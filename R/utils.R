# @staticimports inst/staticexports/
#   str_trim
#   is_AsIs
#   is_html_tag is_html_chr is_html_any

# @staticimports pkg:staticimports
#   os_name
#   %||%
#   is_installed

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
#' Copy all items from the environment to a new environment. By default, the new
#' environment will share the same parent environment.
#'
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
#'
#' @param envir environment to duplicate
#' @param parent parent environment to set for the new environment.  Defaults to
#'   the parent environment of \code{envir}.
#'
#' @return A duplicated copy of `envir` whose parent env is `parent`.
#'
#' @export
duplicate_env <- function(envir, parent = parent.env(envir)) {
  # If we are duplicating the globalenv, we can't use the globalenv's parent
  # as the new env's parent or the new env will be severed from the search path.
  parent <- if (identical(envir, globalenv())) globalenv() else parent

  list2env(
    as.list.environment(envir, all.names = TRUE, sorted = FALSE),
    parent = parent
  )
}

py_global_env <- function() {
  rlang::check_installed("reticulate")
  reticulate::py
}

py_global_dict <- function() {
  # extract all objects of `reticulate::py` (the main module)
  reticulate::py_get_attr(py_global_env(), "__dict__")
}

#' Create a duplicate of a Python environment
#'
#' @examples
#' \dontrun{
#' reticulate::py_run_string("x = 3")
#' new_py_envir <- py_copy_global_env()
#' new_py_envir$items()
#' }
#'
#' @return a Python `Dict` or dictionary
#' @noRd
py_copy_global_env <- function() {
  rlang::check_installed("reticulate", "Python exercise support")

  py_utils <- py_learnr_utilities()

  # Calling `py_utils$deep_copy` results in a hybrid R-Python object, but
  # invoking via `py_call` returns a Python object without R conversion
  reticulate::py_call(py_utils$deep_copy, py_global_dict())
}

py_learnr_utilities <- function() {
  py_env_dict <- py_global_dict()
  utilities <- py_env_dict[["__learnr__"]]
  if (!is.null(utilities)) {
    return(utilities)
  }

  learnr_py <- system.file("internals", "learnr.py", package = "learnr")
  reticulate::py_run_file(learnr_py,convert = FALSE)[["__learnr__"]]
}

#' This clears the Python environment `py`.
#'
#' It will keep important initial objects such as `py` (main module),
#' `r` (reticulate interface to R), and the `builtins` module.
#'
#' @examples
#' \dontrun{
#' reticulate::py_run_string("x = 3")
#' # this removes the `x`
#' py_clear_env()
#' }
#'
#' @return Nothing
#' @noRd
py_clear_env <- function() {
  Map(names(py_global_env()), f = function(obj_name) {
    # prevent the "base" python objects from being removed
    if (!obj_name %in% c("r", "sys", "builtins")) {
      reticulate::py_run_string(paste0("del ", obj_name))
    }
  })
  return(invisible())
}

local_py_env <- function(envir = parent.frame()) {
  withr::defer(py_clear_env(), envir = envir)
}

# backport errorCondition for R < 3.6.0
if (getRversion() < package_version("3.6.0")) {
  errorCondition <- function(msg, ..., class = NULL, call = NULL) {
    structure(
      list(message = msg, call = call, ...),
      class = c(class, "error", "condition")
    )
  }
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
str_match_all <- function(x, pattern, ...) {
  if_no_match_return_null(
    regmatches(x, gregexpr(pattern, x, ...))[[1]]
  )
}
str_replace <- function(x, pattern, replacement) {
  if (is.null(x)) return(NULL)
  sub(pattern, replacement, x)
}
str_replace_all <- function(x, pattern, replacement) {
  if (is.null(x)) return(NULL)

  if (!is.null(names(pattern))) {
    for (i in seq_along(pattern)) {
      x <- str_replace_all(x, names(pattern)[[i]], pattern[[i]])
    }

    return(x)
  }

  gsub(pattern, replacement, x)
}

str_remove <- function(x, pattern) {
  str_replace(x, pattern, "")
}
str_extract <- function(x, pattern, ...) {
  unlist(regmatches(x, regexpr(pattern, x, ...)))
}

knitr_engine <- function(engine) {
  tolower(engine %||% "r")
}

timestamp_utc <- function() {
  strftime(Sys.time(), "%F %H:%M:%OS3 %Z", tz = "UTC")
}

html_code_block <- function(x, escape = TRUE) {
  if (escape) {
    x <- htmltools::htmlEscape(x)
  }

  sprintf("<pre><code>%s</code></pre>", x)
}
