exercise_cache_env <- new.env(parent=emptyenv())
question_cache_env <- new.env(parent = emptyenv())

prepare_tutorial_state <- function(session) {
  clear_exercise_cache_env()
  clear_question_cache_env()
  session$userData$tutorial_state <- reactiveValues()
}

# Store an exercise setup chunk
# Returns TRUE if it was saved, FALSE if it declined to overwrite an existing value
store_exercise_setup_chunk <- function(name, code, overwrite = FALSE){
  if (!overwrite && exists(name, envir = exercise_cache_env)) {
    return(FALSE)
  }
  if (is.null(code)){
    code <- ""
  }
  assign(name, code, envir = exercise_cache_env)
  TRUE
}

# Gets the global setup chunk to run for out-of-process evaluators.
get_global_setup <- function(){
  if (exists("__setup__", envir = exercise_cache_env)) {
    setup <- get("__setup__", envir = exercise_cache_env)
    return(paste0(setup, collapse="\n"))
  }
  NULL
}

# Store setup chunks for an exercise or non-exercise chunk.
store_exercise_cache <- function(name, chunks, overwrite = FALSE){
  if (!overwrite && exists(name, envir = exercise_cache_env)) {
    return(FALSE)
  }
  if (is.null(chunks)){
    return(FALSE)
  }
  assign(name, chunks, envir = exercise_cache_env)
  TRUE
}

# Return a list of knitr chunks for a given exercise label (exercise + setup chunks).
get_exercise_cache <- function(label = NULL){
  if (is.null(label)) {
    chunk_labels <- ls(envir = exercise_cache_env, all.names = TRUE)
    names(chunk_labels) <- chunk_labels
    return(lapply(chunk_labels, get, envir = exercise_cache_env))
  }
  if (exists(label, envir = exercise_cache_env)) {
    setup <- get(label, envir = exercise_cache_env)
    return(setup)
  }
  NULL
}

clear_exercise_cache_env <- function(){
  rm(list=ls(exercise_cache_env, all.names=TRUE), envir=exercise_cache_env)
}

# For backwards compatibility, exercise_cache_env was previously called setup_chunks
clear_exercise_setup_chunks <- clear_exercise_cache_env



# Question Cache ----------------------------------------------------------

store_question_cache <- function(question, overwrite = FALSE){
  label <- question$label
  if (!overwrite && exists(label, envir = question_cache_env)) {
    return(FALSE)
  }
  if (is.null(question)){
    return(FALSE)
  }
  assign(label, question, envir = question_cache_env)
  TRUE
}

# Return a list of knitr chunks for a given exercise label (exercise + setup chunks).
get_question_cache <- function(label = NULL){
  if (is.null(label)) {
    labels <- ls(envir = question_cache_env, all.names = TRUE)
    names(labels) <- labels
    return(lapply(labels, get, envir = question_cache_env))
  }
  if (exists(label, envir = question_cache_env)) {
    q <- get(label, envir = question_cache_env)
    return(q)
  }
  NULL
}

clear_question_cache_env <- function(){
  rm(list=ls(question_cache_env, all.names=TRUE), envir=question_cache_env)
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
  if (is.null(label)) {
    session$userData$tutorial_state
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
#'   - `user_id`: The current user.
#'   - `learnr_version`: The current version of the running learnr package.
#'   - `language`: The current language of the tutorial, either as chosen by the
#'     user or as specified in the `language` item of the YAML front matter.
#'
#' @seealso [get_tutorial_state()]
#'
#' @export
get_tutorial_info <- function(session = getDefaultReactiveDomain()) {
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
    user_id = read_session_request("tutorial.user_id"),
    learnr_version = as.character(utils::packageVersion("learnr")),
    language = read_session_request("tutorial.language")
  )
}
