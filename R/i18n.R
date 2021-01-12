i18n_process_language_options <- function(language = NULL) {
  # Take the language entry from the tutorial options or YAML header and process
  # into the list of resources used when initializing the i18next translations

  is_path_json <- function(x) {
    checkmate::test_string(
      x,
      na.ok = FALSE,
      null.ok = FALSE,
      pattern = "[.]json$",
      ignore.case = TRUE
    )
  }

  if (is_path_json(language)) {
    language <- i18n_read_json(language)
  }

  custom <- list()
  if (is.null(language) || (is.character(language) && length(language) == 1)) {
    ## language: en
    ## language: fr
    default <- if (!is.null(language)) language else "en"
  } else {
    ## language
    ##   en:
    ##     button:
    ##       continue: Got it!
    ##   es:
    ##     button:
    ##       continue: Continuar
    ##   fr: learnr.fr.json

    if (!is.list(language) || is.null(names(language))) {
      stop(
        "`language` must be a single character language code or ",
        "a named list of customizations indexed by language code ",
        'as described in `vignette("multilang", package = "learnr")`',
        call. = FALSE
      )
    }

    # the first language in this format is the default language
    default <- names(language)[1]

    for (lng in names(language)) {
      if (is_path_json(language[[lng]])) {
        language[[lng]] <- i18n_read_json(language[[lng]])
      }

      language[[lng]] <- i18n_validate_customization(language[[lng]])

      if (is.null(language[[lng]])) next
      custom[[lng]] <- list(custom = language[[lng]])
    }
  }

  # Get default translations and then merge in customizations
  translations <- i18n_translations()
  if (length(custom) > 0) {
    for (lang in union(names(translations), names(custom))) {
      translations[[lang]] <- c(translations[[lang]], custom[[lang]])
    }
  }

  list(language = default, resources = translations)
}

i18n_read_json <- function(path) {
  tryCatch(
    jsonlite::read_json(path, simplifyDataFrame = FALSE, simplifyMatrix = FALSE),
    error = function(e) {
      message("Unable to read custom language JSON file at: ", path)
      NULL
    }
  )
}

i18n_validate_customization <- function(lng) {
  if (is.null(lng)) {
    # NULL language items are okay, esp as the first lang (default)
    return(NULL)
  }

  # returns a valid language customization or NULL
  # always throws warnings, not errors
  default <- i18n_translations()$en$translation
  group_keys <- names(default)

  if (!is.list(lng) || is.null(names(lng))) {
    warning(
      "Custom languages must be lists with entries: ",
      paste(group_keys, collapse = ", "),
      immediate. = TRUE
    )
    return(NULL)
  }

  # Let extra keys through for custom components but warn in case accidental
  extra_group_keys <- setdiff(names(lng), group_keys)
  if (length(extra_group_keys)) {
    warning(
      "Ignoring extra customization groups ", paste(extra_group_keys, collapse = ", "),
      immediate. = TRUE
    )
  }

  for (group in intersect(names(lng), group_keys)) {
    extra_keys <- setdiff(names(lng[[group]]), names(default[[group]]))
    if (length(extra_keys)) {
      warning(
        "Ignoring extra ", group, " language customizations: ",
        paste(extra_keys, collapse = ", "),
        immediate. = TRUE
      )
    }
  }

  lng
}

i18n_translations <- function() {
  list(
    en = list(
      translation = list(
        button = list(
          runcode = "Run Code",
          hints = "Hints",
          startover = "Start Over",
          continue = "Continue",
          submitanswer = "Submit Answer",
          previoustopic = "Previous Topic",
          nexttopic = "Next Topic"
        ),
        text = list(
          startover = "Start Over",
          areyousure = "Are you sure you want to start over? (all exercise progress will be reset)",
          youmustcomplete = "You must complete the",
          inthissection = "in this section before continuing."
        )
      )
    ),
    fr = list(
      translation = list(
        button = list(
          runcode = "Lancer le Code",
          hints = "Indice",
          startover = "Recommencer",
          continue = "Continuer",
          submitanswer = "Soumettre",
          previoustopic = "Chapitre pr\u00e9c\u00e9dent",
          nexttopic = "Chapitre Suivant"
        ),
        text = list(
          startover = "Recommencer",
          areyousure = "\u00cates-vous certains de vouloir recommencer ? (La progression sera remise \u00e0 z\u00e9ro)",
          youmustcomplete = "Vous devez d'abord compl\u00e9ter l'exercice",
          inthissection = "de cette section avec de continuer."
        )
      )
    ),
    emo = list(
      translation = list(
        button = list(
          runcode = "\U0001f3c3",
          hints = "\U0001f50e",
          startover = "\u23ee",
          continue = "\u2705",
          submitanswer = "\U0001f197",
          previoustopic = "\u2b05",
          nexttopic = "\u27a1"
        ),
        text = list(
          startover = "\u23ee",
          areyousure = "\U0001f914",
          youmustcomplete = "\u26a0 \U0001f449",
          inthissection = "."
        )
      )
    )
  )
}
