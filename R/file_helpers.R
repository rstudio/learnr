#' Make remote files accessible in a tutorial
#'
#' @description
#' By default, all files in the `data/` directory alongside a tutorial will be
#' accessible within the tutorial.
#' `use_remote_files()` makes files stored remotely (e.g. online) accessible
#' as well.
#'
#' To use remote files in a `learnr` tutorial, you can either include a call to
#' `use_remote_files()` in your global setup chunk:
#'
#' ````
#' ```{r setup, include = FALSE}
#' library(learnr)
#' use_remote_files(
#'  "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi.csv" = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#' ```
#' ````
#'
#' Alternatively, you can call `use_remote_files()` in a separate, standard
#' R chunk (with `echo = FALSE`):
#'
#' ````
#' ```{r setup-files, echo = FALSE}
#' use_remote_files(
#'   "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi.csv" = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#' ```
#' ````
#'
#' @param ... Remote files to include in the tutorial.
#'   Each file will be accessible at `"data/<name of input>"`.
#'   Unnamed arguments have their name set by default with [basename()].
#'
#' @return Sets [knitr chunk options][knitr::opts_chunk]
#'
#' @export
#'
#' @examples
#' use_remote_files(
#'   "https://covidtracking.com/api/v1/states/daily.csv",
#'   "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#'
#' use_remote_files(
#'   "covid.csv" = "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi.csv"  = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )
#'
#' use_remote_files(
#'   "covid/daily.csv" = "https://covidtracking.com/api/v1/states/daily.csv",
#'   "taxi/trips.csv"  = "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2020-01.csv"
#' )

use_remote_files <- function(...) {
  remote_files <- rlang::flatten_chr(list(...))

  if (isTRUE(getOption('knitr.in.progress'))) {
    if (!identical(knitr::opts_current$get("label"), "setup")) {
      rmarkdown::shiny_prerendered_chunk(
        context = "server-start",
        sprintf(
          "learnr:::set_option_remote_files(%s)",
          dput_to_string(remote_files)
        ),
        singleton = TRUE
      )
    }
  } else {
    set_option_remote_files(remote_files)
  }
}

prepare_data_files <- function() {
  local_files <- find_local_files() # Find files in `data/` directory

  # Find files set by `use_remote_files()`
  remote_files <- get_option_remote_files()

  if (!is.null(remote_files)) {
    # Create temporary directory to cache remote files
    temp_dir     <- file.path(tempdir(), "data")
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
  set_option_exercise_files(files)
}

find_local_files <- function() {
  data_contents <- dir("data", recursive = TRUE)

  if (is.null(data_contents)) {return(NULL)}

  # Generate paths to files in the `data/` directory
  local_files        <- normalizePath(file.path("data", data_contents))
  names(local_files) <- data_contents

  local_files
}

set_option_exercise_files <- function(files) {
  knitr::opts_chunk$set(exercise.files = files)
}

get_option_exercise_files <- function(exercise = NULL) {
  default_files <- knitr::opts_chunk$get("exercise.files")

  manual_exercise_files <- exercise$options$exercise.files
  manual_remote_files   <- exercise$options$exercise.remote.files

  if (!is.null(c(manual_exercise_files, manual_remote_files))) {
    warning(
      paste(
        "Manually setting the `exercise.files` or `exercise.remote.files`",
        "chunk options causes suboptimal performance.\nPlease see",
        "`?learnr::use_remote_files` for more information."
      )
    )
  }

  c(default_files, manual_exercise_files, manual_remote_files)
}

set_option_remote_files <- function(files) {
  if (any(!is_url(files) & !is_system_file(files))) {
    stop(
      "Remote files must be either URLs or the result of a call to ",
      "`system.file()`.",
      call. = FALSE
    )
  }

  knitr::opts_chunk$set(exercise.remote.files = files)
}

get_option_remote_files <- function() {
  knitr::opts_chunk$get("exercise.remote.files")
}

copy_data_files <- function(files, dest_dir = "data") {
  if (!length(files)) {return(NULL)}

  # If a name is not specified, default to the basename of the file
  names(files)[names(files) == ""] <- basename(files[names(files) == ""])

  dest_path <- file.path(dest_dir, names(files))

  for (i in seq_along(files)) {
    # Allow authors to add files in nested directories
    dir.create(dirname(dest_path[[i]]), showWarnings = FALSE, recursive = TRUE)
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

is_system_file <- function(path) {
  apply(
    as.matrix(
      vapply(.libPaths(), grepl, logical(length(path)), path, fixed = TRUE)
    ),
    1,
    any
  )
}

is_url <- function(path) {
  grepl("^((http|ftp)s?|sftp)://", path)
}