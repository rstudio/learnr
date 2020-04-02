
# Store an exercise setup chunk
# TODO: scrub this environment before running exercises locally so users don't
# have access to the setup code from within their exercises.
# TODO: use this cache instead of serializing the setup chunks into the client.
setup_chunks <- new.env()
store_exercise_setup_chunk <- function(name, code){
  assign(name, code, envir=setup_chunks)
}

# Gets the global setup chunk to run for out-of-process evaluators.
#  1. If a chunk named `setup-global-exercise` exists, it returns that.
#  2. If not, it looks for a chunk called `setup` and returns that.
#  3. If neither is found, it returns NULL.
get_global_setup <- function(warn_if_using_setup = FALSE){
  if (exists("__setup_global_exercise__", envir = setup_chunks)) {
    return(get("__setup_global_exercise__", envir = setup_chunks))
  } else if (exists("__setup__", envir = setup_chunks)) {
    if (warn_if_using_setup) {
      warning("Because no chunk named `setup-global-exercise` exists, we'll run the `setup` chunk before evaluating each user exercise. Be aware that this exposes the contents of the `setup` chunk to any user who runs exercises.")
    }
    return(get("__setup__", envir = setup_chunks))
  }
  NULL
}