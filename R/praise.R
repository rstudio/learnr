
#' Random praise and encouragement
#'
#' Random praises and encouragements sayings to compliment your question and
#' quiz experience.
#'
#' @param language The language for the random phrase. The currently supported
#'   languages include: `en` and `debug` (static phrases).
#'
#' @return Character string with a random saying
#' @export
#' @rdname random_praise
random_praise <- function(language = NULL) {
  sample(random_phrases("praise", language), 1)
}

#' @export
#' @rdname random_praise
random_encouragement <- function(language = NULL) {
  sample(random_phrases("encouragement", language), 1)
}

read_random_phrases <- function() {
  readRDS(system.file("18n_random_phrases", package = "learnr"))
}

random_phrases_languages <- function() {
  rp <- read_random_phrases()
  sort(Reduce(lapply(rp, names), f = union))
}

random_phrases <- function(type, language = NULL) {
  .random_phrases <- read_random_phrases()

  if (!type %in% names(.random_phrases)) {
    stop.(
      "`type` should be one of ",
      knitr::combine_words(paste0("'", names(.random_phrases), "'"), and = " or ")
    )
  }

  warn_unsupported_language <- function(language, default = "en") {
    if (is.null(language)) {
      return(warn_unsupported_language(default))
    }
    if (!language %in% names(.random_phrases[[type]])) {
      warning(
        "learnr doesn't know how to provide ", type, " in the language '", language, "'",
        call. = FALSE
      )
      return(warn_unsupported_language(default))
    }
    language
  }

  language <- warn_unsupported_language(language, i18n_get_language_option())

  .random_phrases[[type]][[language]]
}
