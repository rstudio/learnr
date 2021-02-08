exercise_cache_env <- new.env(parent=emptyenv())

# Store an exercise setup chunk
# Returns TRUE if it was saved, FALSE if it declined to overwrite an existing value
# TODO: use this cache instead of serializing the setup chunks into the client.
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
  } else if (exists(label, envir = exercise_cache_env)) {
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
