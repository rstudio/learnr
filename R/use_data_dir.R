#' Make files in a directory accessible to tutorials
#'
#' By default, `learnr` tutorials can access files in a `data/` directory within
#' the same directory as the tutorial's R Markdown file. `use_data_dir()` allows
#' you to expose files in a different directory (e.g. the `data/` directory of a
#' different tutorial) to avoid duplicating files.
#'
#' @param dir A directory
#'
#' @return Invisibly returns the specified directory
#' @export
#' @examples \dontrun{
#' use_data_dir("../other_tutorial/data")
#' }

use_data_dir <- function(dir = "data") {
  if (!dir.exists(dir)) {
    rlang::warn(paste0('The data directory "', dir, '" could not be found.'))
  }

  options(learnr.data_dir = dir)

  invisible(dir)
}

copy_data_dir <- function(exercise_dir) {
  # First check environment variable, then options(), then default to "data/"
  source_dir <- Sys.getenv(
    "LEARNR_DATA_DIR", unset = getOption("learnr.data_dir", default = "data")
  )

  if (!dir.exists(source_dir)) {return(invisible(NULL))}

  dest_dir <- file.path(exercise_dir, "data")
  dir.create(dest_dir)

  if (!dir.exists(dest_dir)) {
    rlang::abort('The user-facing data directory was not created successfully.')
  }

  file.copy(dir(source_dir, full.names = TRUE), dest_dir, recursive = TRUE)

  return(invisible(dest_dir))
}