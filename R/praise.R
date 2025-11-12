#' Random praise and encouragement
#'
#' Random praises and encouragements sayings to compliment your question and
#' quiz experience.
#'
#' @examples
#' random_praise()
#' random_praise()
#'
#' random_encouragement()
#' random_encouragement()
#'
#' @param language The language for the random phrase. The currently supported
#'   languages include: `en`, `es`, `pt`, `pl`, `tr`, `de`, `emo`, and `testing`
#'   (static phrases).
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
  readRDS(system.file(
    "internals",
    "i18n_random_phrases.rds",
    package = "learnr"
  ))
}

random_phrases_languages <- function() {
  rp <- read_random_phrases()
  sort(Reduce(lapply(rp, names), f = union))
}

random_phrases <- function(type, language = NULL) {
  .random_phrases <- merge_random_phrases()

  if (!type %in% names(.random_phrases)) {
    stop.(
      "`type` should be one of ",
      knitr::combine_words(
        paste0("'", names(.random_phrases), "'"),
        and = " or "
      )
    )
  }

  warn_unsupported_language <- function(language, default = "en") {
    # warns if requested language isn't supported,
    # otherwise recurses to fall back to default
    if (is.null(language)) {
      return(warn_unsupported_language(default))
    }
    if (!language %in% names(.random_phrases[[type]])) {
      learnr_render_message(
        "learnr doesn't know how to provide ",
        type,
        " in the language '",
        language,
        "'",
        level = "warn"
      )
      return(warn_unsupported_language(default))
    }
    language
  }

  language <- warn_unsupported_language(language, i18n_get_language_option())

  .random_phrases[[type]][[language]]
}

#' Add phrases to the bank of random phrases
#'
#' Augment the random phrases available in [random_praise()] and
#' [random_encouragement()] with phrases of your own. Note that these phrases
#' are added to the existing phrases, rather than overwriting them.
#'
#' @section Usage in learnr tutorials:
#'
#' To add random phrases in a learnr tutorial, you can either include one or
#' more calls to `random_phrases_add()` in your global setup chunk:
#'
#' ````
#' ```{r setup, include = FALSE}`r ''`
#' library(learnr)
#' random_phrases_add(
#'   language = "en",
#'   praise = "Great work!",
#'   encouragement = "I believe in you."
#' )
#' ```
#' ````
#'
#' Alternatively, you can call `random_phrases_add()` in a separate, standard
#' R chunk (with `echo = FALSE`):
#'
#' ````
#' ```{r setup-phrases, echo = FALSE}`r ''`
#' random_phrases_add(
#'   language = "en",
#'   praise = c("Great work!", "You're awesome!"),
#'   encouragement = c("I believe in you.", "Yes we can!")
#' )
#' ```
#' ````
#'
#' @examples
#' random_phrases_add("demo", praise = "Great!", encouragement = "Try again.")
#' random_praise(language = "demo")
#' random_encouragement(language = "demo")
#'
#'
#' @param language The language of the phrases to be added.
#' @param praise,encouragement A vector of praising or encouraging phrases,
#'   including final punctuation.
#'
#' @return Returns the previous custom phrases invisibly when called in the
#'   global setup chunk or interactively. Otherwise, it returns a shiny pre-
#'   rendered chunk.
#'
#' @export
random_phrases_add <- function(
  language = "en",
  praise = NULL,
  encouragement = NULL
) {
  phrases <- list()
  if (!is.null(praise)) {
    stopifnot(is.character(praise))
    phrases$praise <- list()
    phrases$praise[[language]] <- praise
  }
  if (!is.null(encouragement)) {
    stopifnot(is.character(encouragement))
    phrases$encouragement <- list()
    phrases$encouragement[[language]] <- encouragement
  }
  if (isTRUE(getOption('knitr.in.progress'))) {
    if (!identical(knitr::opts_current$get("label"), "setup")) {
      rmarkdown::shiny_prerendered_chunk(
        context = "server-start",
        singleton = TRUE,
        sprintf(
          "learnr:::update_custom_random_phrases(%s)",
          dput_to_string(phrases)
        )
      )
    }
  } else {
    update_custom_random_phrases(phrases)
  }
}

update_custom_random_phrases <- function(x) {
  custom_phrases <- knitr::opts_chunk$get("tutorial.random_phrases")
  if (is.null(custom_phrases)) {
    knitr::opts_chunk$set("tutorial.random_phrases" = x)
    return(invisible(custom_phrases))
  }

  new_phrases <- merge_random_phrases(x, custom_phrases)

  knitr::opts_chunk$set("tutorial.random_phrases" = new_phrases)
  invisible(custom_phrases)
}

merge_random_phrases <- function(
  new = knitr::opts_chunk$get("tutorial.random_phrases"),
  current = read_random_phrases()
) {
  if (is.null(new)) {
    return(current)
  }
  for (type in names(new)) {
    for (lang in names(new[[type]])) {
      current[[type]][[lang]] <- c(
        current[[type]][[lang]],
        new[[type]][[lang]]
      )
    }
  }
  current
}
