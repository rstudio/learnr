#' Make remote files accessible in a tutorial
#'
#' By default, all files in the `data/` directory alongside a tutorial will be
#' accessible within the tutorial.
#' `use_remote_files()` makes files stored remotely (e.g. online) accessible
#' as well.
#'
#' @section Usage in learnr tutorials:
#'
#' To use remote files in a `learnr` tutorial, you can either include a call to
#' `use_remote_files()` in your global setup chunk:
#'
#' ````
#' ```{r setup, include = FALSE}`r ''`
#' library(learnr)
#' use_remote_files(
#'
#' )
#' ```
#' ````
#'
#' Alternatively, you can call `random_phrases_add()` in a separate, standard
#' R chunk (with `echo = FALSE`):
#'
#' ````
#' ```{r setup-phrases, echo = FALSE}`r ''`
#' use_remote_file(
#'   "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi.csv" = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#' ```
#' ````
#'
#' @examples
#' use_remote_file(
#'   "https://covidtracking.com/api/v1/states/daily.csv",
#'   "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#'
#' use_remote_file(
#'   "covid.csv" = "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi.csv"  = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#'
#'
#' @param ... Remote files to include in the tutorial.
#'   Each file will be accessible at `data/<name of input>`.
#'   Unnamed arguments have their name set by default with [basename()].
#'
#' @return Sets [`knitr` chunk options][knitr::opts_chunk]
#'
#' @export

use_remote_files <- function(...) {
  data_files <- rlang::flatten_chr(list(...))
  knitr::opts_chunk$set(exercise.remote.files = data_files)
}

prepare_data_files <- function() {
  # Find files in `data/` directory
  local_files <- dir("data", recursive = TRUE)

  if (!is.null(local_files)) {
    # Generate paths to files in the `data/` directory
    local_files <- normalizePath(
      dir("data", recursive = TRUE, full.names = TRUE)
    )
    names(local_files) <- dir("data", recursive = TRUE)
  }

  # Find files set by `use_remote_files()`
  remote_files <- knitr::opts_chunk$get()$exercise.remote.files

  if (!is.null(remote_files)) {
    # Create temporary directory to cache remote files
    temp_dir <- file.path(tempdir(), "data")
    # Copy remote files into temporary directory
    remote_files <- copy_data_files(remote_files, temp_dir)

    # Generate paths to files in the temporary directory
    remote_files <- normalizePath(
      dir(temp_dir, recursive = TRUE, full.names = TRUE)
    )
    names(remote_files) <- dir(temp_dir, recursive = TRUE)
  }

  # Combine paths to local files and remote files
  files <- c(local_files, remote_files)

  # Specify full paths in chunk options
  knitr::opts_chunk$set(exercise.files = files)
}

copy_data_files <- function(files, dest_dir = "data") {
  # If a name is not specified, default to the basename of the file
  names(files)[names(files) == ""] <- basename(files[names(files) == ""])

  # Paths files will be copied into
  dest_path <- file.path(dest_dir, names(files))

  for (i in seq_along(files)) {
    # Create directory structure
    dir.create(dirname(dest_path[[i]]), showWarnings = FALSE, recursive = TRUE)

    # Copy files
    copy_file(files[[i]], dest_path[[i]])
  }

  files
}

copy_file <- function(from, to, ...) {
  if (is_url(from)) {
    download.file(from, to, ...)
  } else {
    file.copy(from, to, ...)
  }
}

is_url <- function(path) {
  grepl("^((http|ftp)s?|sftp)://", path)
}