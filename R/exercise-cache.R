exercise_cache_env <- new.env(parent=emptyenv())
question_cache_env <- new.env(parent = emptyenv())

clear_tutorial_cache <- function() {
  clear_exercise_cache_env()
  clear_question_cache_env()
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
    chunk_labels <- ls(exercise_cache_env)
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
    labels <- ls(question_cache_env)
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
