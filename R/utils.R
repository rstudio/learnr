"%||%" <- function(x, y) if (is.null(x)) y else x

is_windows <- function() {
  .Platform$OS.type == 'windows'
}

is_macos <- function() {
  Sys.info()[["sysname"]] == "Darwin"
}


is_localhost <- function(location) {
  if (is.null(location))
    # caused when using devtools::load_all(), which is a localhost
    TRUE
  else if (location$hostname %in% c("localhost", "127.0.0.1"))
    TRUE
  else if (nzchar(Sys.getenv("RSTUDIO")) && grepl("/p/\\d+/", location$pathname))
    TRUE
  else
    FALSE
}

stop. <- function(...) {
  stop(..., call. = FALSE)
}


#' Create a duplicate of an environment
#'
#' Copy all items from the environment to a new environment.
#' By default, the new environment will share the same parent environment.
#' @param envir environment to duplicate
#' @param parent parent environment to set for the new environment.  Defaults to the parent environment of \code{envir}.
#' @export
#' @examples
#' # Make a new environment with the object 'key'
#' envir <- new.env()
#' envir$key <- "value"
#' "key" %in% ls() # FALSE
#' "key" %in% ls(envir = envir) # TRUE
#'
#' # Duplicate the envir and show it contains 'key'
#' new_envir <- duplicate_env(envir)
#' "key" %in% ls(envir = new_envir) # TRUE
duplicate_env <- function(envir, parent = parent.env(envir)) {
  list2env(
    as.list.environment(envir, all.names = TRUE, sorted = FALSE),
    parent = parent
  )
}




str_trim <- function(x) {
  sub(
    "\\s+$", "",
    sub(
      "^\\s+", "",
      as.character(x)
    )
  )
}

if_no_match_return_null <- function(x) {
  if (length(x) == 0) {
    NULL
  } else {
    x
  }
}
str_match <- function(x, pattern) {
  if_no_match_return_null(
    regmatches(x, regexpr(pattern, x))
  )

}
str_match_all <- function(x, pattern) {
  if_no_match_return_null(
    regmatches(x, gregexpr(pattern, x))[[1]]
  )
}
str_replace <- function(x, pattern, replacement) {
  if (is.null(x)) return(NULL)
  sub(pattern, replacement, x)
}
str_remove <- function(x, pattern) {
  str_replace(x, pattern, "")
}


is_tags <- function(x) {
  inherits(x, "shiny.tag") ||
    inherits(x, "shiny.tag.list")
}
