"%||%" <- function(x, y) if (is.null(x)) y else x

is_windows <- function() {
  .Platform$OS.type == 'windows'
}

is_macos <- function() {
  Sys.info()[["sysname"]] == "Darwin"
}


is_localhost <- function(location) {
  if (location$hostname %in% c("localhost", "127.0.0.1"))
    TRUE
  else if (nzchar(Sys.getenv("RSTUDIO")) && grepl("/p/\\d+/", location$pathname))
    TRUE
  else
    FALSE
}


# Create an new, 'twin' environment with the same objects and same parent.
twin_env <- function(envir, parent = parent.env(envir)) {
  new_envir <- new.env(parent = parent)
  for (object in ls(envir = envir))
    new_envir[[object]] <- envir[[object]]
  new_envir
}
