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

  options(tutorial.data.dir = dir)

  invisible(dir)
}

copy_data_dir <- function(exercise_dir) {
  # First check options(), then environment variable, then default to "data/"
  source_dir <- getOption(
    "tutorial.data.dir", default = Sys.getenv("TUTORIAL_DATA_DIR", unset = "")
  )

  if (identical(source_dir, "")) {
    if (dir.exists("data")) {
      source_dir <- "data"
    } else {
      return(invisible(NULL))
    }
  }

  if (!dir.exists(source_dir)) {
    rlang::abort(
      paste("An error occured:",
            "we weren't able to find the data directory for this exercise.")
    )
  }

  dest_dir <- file.path(exercise_dir, "data")
  dir.create(dest_dir)

  if (!dir.exists(dest_dir)) {
    rlang::abort(
      paste("An error occurred:",
            "we weren't able to create the data directory for this exercise.")
    )
  }

  file.copy(dir(source_dir, full.names = TRUE), dest_dir, recursive = TRUE)

  return(invisible(dest_dir))
}
