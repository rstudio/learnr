tutorial_cache_env <- new.env(parent = emptyenv())

prepare_tutorial_state <- function(session) {
  clear_tutorial_cache()
  session$userData$tutorial_state <- reactiveValues()
}

clear_tutorial_cache <- function() {
  assign("objects", list(), tutorial_cache_env)
  tutorial_cache_env$setup <- NULL
  invisible(TRUE)
}

store_tutorial_cache <- function(name, object, overwrite = FALSE) {
  if (!overwrite && name %in% names(tutorial_cache_env$objects)) {
    return(FALSE)
  }
  if (is.null(object)){
    return(FALSE)
  }
  tutorial_cache_env$objects[[name]] <- object
  TRUE
}

get_tutorial_cache <- function(type = c("all", "question", "exercise")) {
  type <- match.arg(type)

  filter_type <- function(x) {
    inherits(x, paste0("learnr_", type))
  }

  switch(
    type,
    "all" = tutorial_cache_env$objects,
    Filter(filter_type, tutorial_cache_env$objects)
  )
}


# Exercises ---------------------------------------------------------------

# Gets the global setup chunk to run for out-of-process evaluators.
get_global_setup <- function() {
  if ("__setup__" %in% names(tutorial_cache_env$objects)) {
    setup <- tutorial_cache_env$objects[["__setup__"]]
    return(paste0(setup, collapse="\n"))
  }
  NULL
}

# Store setup chunks for an exercise or non-exercise chunk.
store_exercise_cache <- function(exercise, overwrite = FALSE) {
  label <- exercise$options$label
  store_tutorial_cache(name = label, object = exercise, overwrite = overwrite)
}

# Return the exercise object from the cache for a given label
get_exercise_cache <- function(label = NULL){
  exercises <- get_tutorial_cache(type = "exercise")
  if (is.null(label)) {
    return(exercises)
  }
  exercises[[label]]
}

clear_exercise_cache_env <- function() {
  .Deprecated("clear_tutorial_cache")
  clear_tutorial_cache()
}

# For backwards compatibility, exercise_cache_env was previously called setup_chunks
clear_exercise_setup_chunks <- clear_exercise_cache_env


# Questions ---------------------------------------------------------------

store_question_cache <- function(question, overwrite = FALSE){
  label <- question$label
  store_tutorial_cache(name = label, object = question, overwrite = overwrite)
}

# Return a list of knitr chunks for a given exercise label (exercise + setup chunks).
get_question_cache <- function(label = NULL){
  questions <- get_tutorial_cache(type = "question")
  if (is.null(label)) {
    return(questions)
  }
  questions[[label]]
}

clear_question_cache_env <- function() {
  .Deprecated("clear_tutorial_cache")
  clear_tutorial_cache()
}


# Tutorial State ----------------------------------------------------------

#' Observe the user's progress in the tutorial
#'
#' @description
#' As a student progresses through a \pkg{learnr} tutorial, their progress is
#' stored in a Shiny reactive values list for their session (see
#' [shiny::reactiveValues()]). Without arguments, `get_tutorial_state()` returns
#' the full reactiveValues object that can be converted to a conventional list
#' with [shiny::reactiveValuesToList()]. If the `label` argument is provided,
#' the state of an individual question or exercise with that label is returned.
#'
#' Calling `get_tutorial_state()` introduces a reactive dependency on the state
#' of returned questions or exercises unless called within `isolate()`. Note
#' that `get_tutorial_state()` will only work for the tutorial author and must
#' be used in a reactive context, i.e. within [shiny::observe()],
#' [shiny::observeEvent()], or [shiny::reactive()]. Any logic observing the
#' user's tutorial state must be written inside a `context="server"` chunk in
#' the tutorial's R Markdown source.
#'
#' @param label A length-1 character label of the exercise or question.
#' @param session The `session` object passed to function given to
#'   `shinyServer.` Default is [shiny::getDefaultReactiveDomain()].
#'
#' @return A reactiveValues object or a single reactive value (if `label` is
#'   provided). The names of the full reactiveValues object correspond to the
#'   label of the question or exercise. Each item contains the following
#'   entries:
#'
#'   - `type`: One of `"question"` or `"exercise"`.
#'   - `answer`: A character vector containing the user's submitted answer(s).
#'   - `correct`: A logical indicating whether the user's answer was correct,
#'     or a logical `NA` if the submission was not checked for correctness.
#'   - `timestamp`: The time at which the user's submission was completed, as
#'     a character string in UTC, formatted as `"%F %H:%M:%OS3 %Z"`.
#'
#' @seealso [get_tutorial_info()]
#' @export
get_tutorial_state <- function(label = NULL, session = getDefaultReactiveDomain()) {
  object_labels <- names(get_tutorial_cache())
  if (is.null(label)) {
    state <- shiny::reactiveValuesToList(session$userData$tutorial_state)
    state[intersect(object_labels, names(state))]
  } else {
    session$userData$tutorial_state[[label]]
  }
}

set_tutorial_state <- function(label, data, session = getDefaultReactiveDomain()) {
  stopifnot(is.character(label))
  if (is.reactive(data)) {
    data <- data()
  }

  if (is.null(data)) {
    session$userData$tutorial_state[[label]] <- NULL
    return()
  }

  stopifnot(is.list(data))
  data$timestamp <- timestamp_utc()
  session$userData$tutorial_state[[label]] <- data
  invisible(data)
}


# Tutorial Info -----------------------------------------------------------

#' Get information about the current tutorial
#'
#' Returns information about the current tutorial. Ideally the function should
#' be evaluated in a Shiny context, i.e. in a chunk with option
#' `context = "server"`. Note that the values of this function may change after
#' the tutorial is completely initialized. If called in a non-reactive context,
#' `get_tutorial_info()` will return default values that will most likely
#' correspond to the current tutorial.
#'
#' @inheritParams get_tutorial_state
#'
#' @return Returns an ordinary list with the following elements:
#'
#'   - `tutorial_id`: The ID of the tutorial, auto-generated or from the
#'     `tutorial$id` key in the tutorial's YAML front matter.
#'   - `tutorial_version`: The tutorial's version, auto-generated or from the
#'     `tutorial$version` key in the tutorial's YAML front matter.
#'   - `items`: A data frame with columns `order`, `label`, `type` and `data`
#'     describing the items (questions and exercises) in the tutorial. This item
#'     is only available in the running tutorial, not during the static
#'     pre-render step.
#'   - `user_id`: The current user.
#'   - `learnr_version`: The current version of the running learnr package.
#'   - `language`: The current language of the tutorial, either as chosen by the
#'     user or as specified in the `language` item of the YAML front matter.
#'
#' @seealso [get_tutorial_state()]
#'
#' @export
get_tutorial_info <- function(session = getDefaultReactiveDomain()) {
  if (identical(Sys.getenv("LEARNR_EXERCISE_USER_CODE", ""), "TRUE")) {
    return()
  }

  read_session_request <- function(key) {
    if (is.null(session)) {
      value <- switch(
        key,
        "tutorial.tutorial_id" = rmarkdown::metadata$tutorial$id %||% default_tutorial_id(),
        "tutorial.tutorial_version" = rmarkdown::metadata$tutorial$version %||% default_tutorial_version(),
        "tutorial.user_id" = default_user_id(),
        "tutorial.language" = default_language(),
        NULL
      )
      return(value)
    }
    read_request(session, key)
  }

  list(
    tutorial_id = read_session_request("tutorial.tutorial_id"),
    tutorial_version = read_session_request("tutorial.tutorial_version"),
    items = describe_tutorial_items(),
    user_id = read_session_request("tutorial.user_id"),
    learnr_version = as.character(utils::packageVersion("learnr")),
    language = read_session_request("tutorial.language")
  )
}

describe_tutorial_items <- function() {
  if (!length(tutorial_cache_env$objects)) {
    return()
  }

  items <- list(
    label = names(tutorial_cache_env$objects),
    type = vapply(
      names(tutorial_cache_env$objects),
      FUN.VALUE = character(1),
      function(x) {
        if (identical(x, "__setup__")) {
          "setup"
        } else if (inherits(tutorial_cache_env$objects[[x]], "learnr_exercise")) {
          "exercise"
        } else if (inherits(tutorial_cache_env$objects[[x]], "tutorial_question")) {
          "question"
        } else {
          "other"
        }
      }
    ),
    data = I(unname(tutorial_cache_env$objects))
  )

  items <- as.data.frame(items, stringsAsFactors = FALSE)
  class(items$data) <- "list"

  idx_setup <- which(items$label == "__setup__")
  if (length(idx_setup)) {
    # make __setup__ the first item with order 0
    order <- c(idx_setup, setdiff(seq_along(items$label), idx_setup))
    items[order, ]
    items$order <- seq_len(nrow(items)) - 1
  } else {
    items$order <- seq_len(nrow(items))
  }

  class(items) <- c("tbl_df", "tbl", "data.frame")
  items[c("order", "label", "type", "data")]
}
