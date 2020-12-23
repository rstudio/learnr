
#' Tutorial HTML dependency
#'
#' @details HTML dependency for core tutorial JS and CSS. This should be included as a
#' dependency for custom tutorial formats that wish to ensure that that
#' tutorial.js and tutorial.css are loaded prior their own scripts and stylesheets.
#'
#' @export
tutorial_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial",
    version = utils::packageVersion("learnr"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial.js",
    stylesheet = "tutorial.css"
  )
}

tutorial_autocompletion_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-autocompletion",
    version = utils::packageVersion("learnr"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial-autocompletion.js"
  )
}

tutorial_diagnostics_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-diagnostics",
    version = utils::packageVersion("learnr"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial-diagnostics.js"
  )
}


html_dependency_src <- function(...) {
  if (nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
    r_dir <- utils::getSrcDirectory(html_dependency_src, unique = TRUE)
    pkg_dir <- dirname(r_dir)
    file.path(pkg_dir, "inst", ...)
  }
  else {
    system.file(..., package = "learnr")
  }
}

idb_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "idb-keyvalue",
    version = "3.2.0",
    src = system.file("lib/idb-keyval", package = "learnr"),
    script = "idb-keyval-iife-compat.min.js",
    all_files = FALSE
  )
}

bootbox_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "bootbox",
    version = "4.4.0",
    src = system.file("lib/bootbox", package = "learnr"),
    script = "bootbox.min.js"
  )
}

clipboardjs_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "clipboardjs",
    version = "1.5.15",
    src = system.file("lib/clipboardjs", package = "learnr"),
    script = "clipboard.min.js"
  )
}


ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "ace",
    version = ACE_VERSION,
    src = system.file("lib/ace", package = "learnr"),
    script = "ace.js"
  )
}

tutorial_i18n <- function() {
  htmltools::htmlDependency(
    name = "i18n",
    version = "1.2.0",
    src = system.file("lib/i18n", package = "learnr"),
    script = c("i18next.min.js", "jquery-i18next.min.js")
  )
}

tutorial_i18n_lang <- function(language) {
  lang_path <- tutorial_i18n_prepare_language_file(language)

  htmltools::htmlDependency(
    name = "learnr_lanaguage",
    version = utils::packageVersion("learnr"),
    src = dirname(lang_path),
    script = basename(lang_path),
    all_files = FALSE
  )
}

tutorial_i18n_prepare_language_file <- function(language) {
  translations <- tutorial_i18n_process_language_options(language)

  lang_text <- htmltools::htmlTemplate(
    system.file("lib/i18n/template.js", package = "learnr"),
    language = translations$default,
    resources = jsonlite::toJSON(translations$translations, auto_unbox = TRUE)
  )

  tmpfile <- file.path(tempdir(), "learnr_i18n_translations.js")
  writeLines(as.character(lang_text), tmpfile)
  tmpfile
}

tutorial_i18n_process_language_options <- function(language = NULL) {
  # Take the language entry from the tutorial options or YAML header and process
  # into the script that initializes the i18next translations

  if (is.null(language) || (is.character(language) && length(language) == 1)) {
    ## language: en
    ## language: fr
    default <- if (!is.null(language)) language else "en"
    custom <- NULL
  } else {
    default <- language$default
    if (is.character(language$custom) && length(language$custom == 1)) {
      ## language:
      ##   default: en
      ##   custom: custom-languages.json
      custom <- tryCatch(
        jsonlite::read_json(language$custom, simplifyDataFrame = FALSE, simplifyMatrix = FALSE),
        error = function(e) {
          message("Unable to read custom language JSON file at: ", language$custom)
          NULL
        }
      )
    } else if (is.list(language$custom) && is.null(names(language$custom))) {
      ## language:
      ##   default: en
      ##   custom:
      ##     - language: en
      ##       button:
      ##         continue: Got it!
      custom <- list()
      for (i in seq_along(language$custom)) {
        lc <- language$custom[[i]]
        lang <- if (!is.null(lc$language)) lc$language else default
        custom <- c(
          custom,
          tutorial_i18n_custom_language(lang, lc$button, lc$text)
        )
      }
    } else if (is.list(language$custom)) {
      ## language:
      ##   default: en
      ##   custom:
      ##     language: en
      ##     button:
      ##       continue: Got it!
      custom <- tutorial_i18n_custom_language(
        language = if (is.null(language$custom$language)) {
          language$default
        } else {
          language$custom$language
        },
        button = language$custom$button,
        text = language$custom$text
      )
    } else {
      custom <- NULL
    }
  }

  if (is.null(default)) default <- "en"

  # Get default translations and then merge in customizations
  translations <- tutorial_i18n_translations()
  if (!is.null(custom)) {
    for (lang in union(names(translations), names(custom))) {
      translations[[lang]] <- c(translations[[lang]], custom[[lang]])
    }
  }

  list(default = default, translations = translations)
}

#' Customize the Language of a learnr Tutorial
#'
#' The language of various elements of a learnr tutorial can be customized via
#' the `language` option of the [learnr::tutorial()] format. To customize the
#' language used in one specific tutorial, the `language` option is recommended.
#' Authors who rely on many customizations or who are providing complete
#' language translations can use `tutorial_i18n_custom_language()` to setup
#' customization settings that can be written into a `.json` file and used
#' across many tutorials. See `vignette("multilang", package = "learnr')` for
#' a complete overview of language customization options.
#'
#' @param language Default language for the custom translation. Translateable
#'   fields without a customization will inherit from the translations for this
#'   language.
#' @param button A list of keys with translations for button text. One of
#'   `r knitr::combine_words(dQuote(names(tutorial_i18n_custom_language_defaults("button", FALSE)), FALSE), and = " or ")`.
#' @param text A list of keys with translations for text elements. One of
#'   `r knitr::combine_words(dQuote(names(tutorial_i18n_custom_language_defaults("text", FALSE)), FALSE), and = " or ")`.
#'
#' @return Returns a list formatted for use with \pkg{learnr} translation
#'   functionality.
#'
#' @examples
#' tutorial_i18n_custom_language(
#'   language = "en",
#'   button = list(runcode = "Run!"),
#'   text = list(startover = "Restart!")
#' )
#'
#' tutorial_i18n_custom_language("es", button = list(runcode = "Ejecutar"))
#'
#' @seealso `vignette("multilang", package = "learnr')`
#' @export
tutorial_i18n_custom_language <- function(language = NULL, button = NULL, text = NULL) {
  if (is.null(button) && is.null(text)) return()
  if (is.null(language)) language <- "en"

  x <- list()
  x[[language]] <- list(custom = list())

  if (!is.null(button)) {
    button_expected <- names(tutorial_i18n_translations()$en$translation$button)
    button_extra <- setdiff(names(button), button_expected)
    if (length(button_extra)) {
      warning("Unexpected `button` translation key(s): ", paste(button_extra, collapse = ", "))
    }

    x[[language]]$custom$button <- button
  }

  if (!is.null(text)) {
    text_expected <- names(tutorial_i18n_translations()$en$translation$text)
    text_extra <- setdiff(names(text), text_expected)
    if (length(text_extra)) {
      warning("Unexpected `text` translation key(s): ", paste(text_extra, collapse = ", "))
    }

    x[[language]]$custom$text <- text
  }

  x
}

tutorial_i18n_custom_language_defaults <- function(parent_key, docs = TRUE) {
  default <- tutorial_i18n_translations()$en$translation
  parent_key <- match.arg(parent_key, names(default))
  x <- default[[parent_key]]
  if (!isTRUE(docs)) return(x)
  paste0(
    parent_key, ":\n",
    paste0("  ", names(x), ": ", unname(unlist(x)), collapse = "\n"),
    sep = ""
  )
}

tutorial_i18n_translations <- function() {
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