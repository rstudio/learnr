
# Store an exercise setup chunk
# Returns TRUE if it was saved, FALSE if it declined to overwrite an existing value
# TODO: use this cache instead of serializing the setup chunks into the client.
setup_chunks <- new.env(parent=emptyenv())
store_exercise_setup_chunk <- function(name, code, overwrite = FALSE){
  if (!overwrite && exists(name, envir = setup_chunks)) {
    return(FALSE)
  }
  assign(name, code, envir = setup_chunks)
  TRUE
}

# Gets the global setup chunk to run for out-of-process evaluators.
get_global_setup <- function(){
  if (exists("__setup__", envir = setup_chunks)) {
    setup <- get("__setup__", envir = setup_chunks)
    return(paste0(setup, collapse="\n"))
  }
  ""
}

clear_exercise_setup_chunks <- function(){
  rm(list=ls(setup_chunks, all.names=TRUE), envir=setup_chunks)
}