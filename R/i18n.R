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

      if (is.null(language[[lng]])) {
        next
      }
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
    jsonlite::read_json(
      path,
      simplifyDataFrame = FALSE,
      simplifyMatrix = FALSE
    ),
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
      "Ignoring extra customization groups ",
      paste(extra_group_keys, collapse = ", "),
      immediate. = TRUE
    )
  }

  for (group in intersect(names(lng), group_keys)) {
    extra_keys <- setdiff(names(lng[[group]]), names(default[[group]]))
    if (length(extra_keys)) {
      warning(
        "Ignoring extra ",
        group,
        " language customizations: ",
        paste(extra_keys, collapse = ", "),
        immediate. = TRUE
      )
    }
  }

  lng
}

i18n_tag <- function(key, ..., opts = NULL, tag = htmltools::span) {
  if (!is.null(opts)) {
    opts <- jsonlite::toJSON(opts, auto_unbox = TRUE, pretty = FALSE)
  }
  x <- tag(..., `data-i18n` = key, `data-i18n-opts` = opts)
  # return an html character object instead of a shiny.tag
  htmltools::HTML(format(x))
}

i18n_span <- function(key, ..., opts = NULL) {
  i18n_tag(key, ..., opts = opts, tag = htmltools::span)
}

i18n_div <- function(key, ..., opts = NULL) {
  i18n_tag(key, ..., opts = opts, tag = htmltools::div)
}

i18n_combine_words <- function(
  words,
  and = c("and", "or"),
  before = "",
  after = before,
  oxford_comma = TRUE
) {
  and <- match.arg(and)
  and <- sprintf(" $t(text.%s) ", and)
  words <- paste0(before, words, after)

  n <- length(words)
  if (oxford_comma && n > 2) {
    words[n - 1] <- paste0(words[n - 1], "$t(text.oxfordcomma)")
  }

  knitr::combine_words(
    words,
    sep = "$t(text.listcomma) ",
    and = and,
    oxford_comma = FALSE
  )
}

i18n_translations <- function() {
  readRDS(system.file("internals", "i18n_translations.rds", package = "learnr"))
}

i18n_set_language_option <- function(language = NULL) {
  # Sets a knitr option for `tutorial.language` using language found in this order
  # 1. `language` provided
  # 2. From read_request()
  # 3. Default

  current <- knitr::opts_knit$get("tutorial.language")
  if (is.null(language)) {
    session <- shiny::getDefaultReactiveDomain()
    language <-
      if (!is.null(session)) {
        read_request(session, "tutorial.language", default_language())
      } else {
        default_language()
      }
  }

  knitr::opts_knit$set(tutorial.language = language)
  i18n_setenv_language(language)

  invisible(current)
}

i18n_setenv_language <- function(lang) {
  lang <- i18n_determine_base_r_language(lang)

  old_lang <- Sys.getenv("LANGUAGE", unset = "en")
  old_text <- gettext("subscript out of bounds", domain = "R")

  Sys.setenv("LANGUAGE" = lang)

  new_lang <- Sys.getenv("LANGUAGE", unset = "en")
  new_text <- gettext("subscript out of bounds", domain = "R")

  if (!identical(old_lang, new_lang) && identical(old_text, new_text)) {
    # On Linux, message translations are cached
    # Messages from the old language may be shown in the new language
    # If this happens, invalidate the cache so new messages have to generate
    base_dir <- bindtextdomain("R-base")
    bindtextdomain("R-base", tempfile())
    bindtextdomain("R-base", base_dir)
  }
}

i18n_determine_base_r_language <- function(lang) {
  lang <- gsub("-", "_", lang)

  # Find available translations of base R
  base_langs <- dir(bindtextdomain("R"))
  base_langs <- base_langs[grepl("^[a-z]{2,3}(_[A-Z]{2})?$", base_langs)]

  # If `lang` is a base R translation, return `lang`
  if (!length(base_langs) || lang %in% base_langs) {
    return(lang)
  }

  lang_code <- substr(lang, 1, 2)

  # If `lang` is a variant of English, base R does not need to be translated
  if (lang_code == "en") {
    return(lang)
  }

  # Special case for Hong Kong and Macao, which should inherit Traditional
  # Chinese (zh_TW) before Simplified Chinese (zh_CN)
  if (lang %in% c("zh_HK", "zh_MO")) {
    zh_langs <- intersect(c("zh_TW", "zh_CN"), base_langs)
    return(paste0(c(lang, zh_langs), collapse = ":"))
  }

  # If `lang` is a variant of a language with a base R translation,
  # use ":" to inherit closest translation. If unmatched, R falls back to English
  has_base_lang_variant <- lang_code == substr(base_langs, 1, 2)
  if (any(has_base_lang_variant)) {
    base_lang_variants <- base_langs[has_base_lang_variant]
    # in case of future added translations, use more generic variant first
    base_lang_variants <- base_lang_variants[order(nchar(base_lang_variants))]
    lang <- c(lang, base_lang_variants)
  }

  paste(lang, collapse = ":")
}

i18n_get_language_option <- function() {
  # 1. knitr option
  lang_knit_opt <- knitr::opts_knit$get("tutorial.language")
  if (!is.null(lang_knit_opt)) {
    return(lang_knit_opt)
  }

  # 2. Shiny current language session as last reported if available
  session <- shiny::getDefaultReactiveDomain()
  lang_session <- if (!is.null(session)) {
    read_request(session, "tutorial.language", NULL)
  }
  if (!is.null(lang_session)) {
    return(lang_session)
  }

  # 3. R option
  lang_r_opt <- getOption("tutorial.language")
  if (!is.null(lang_r_opt)) {
    return(lang_r_opt)
  }

  # 4. final default
  default_language()
}

i18n_observe_tutorial_language <- function(input, session) {
  shiny::observeEvent(input[['__tutorial_language']], {
    write_request(session, 'tutorial.language', input[['__tutorial_language']])
  })
}
