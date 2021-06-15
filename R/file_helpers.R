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
#'   system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
#'   "covid.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
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
#'   system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
#'   "covid.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
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
#'   system.file("examples", "knitr-minimal.Rnw", package = "knitr")
#' )
#'
#' use_remote_files(
#'   "covid.csv"    = "https://covidtracking.com/api/v1/states/daily.csv",
#'   "notebook.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr")
#' )
#'
#' use_remote_files(
#'   "tables/covid.csv"      = "https://covidtracking.com/api/v1/states/daily.csv",
#'   "notebooks/example.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr")
#' )

use_remote_files <- function(...) {
  remote_files <- rlang::flatten_chr(list(...))
  remote_files <- c(get_option_remote_files(), remote_files)

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
  # Find files in `data/` directory
  local_files <- find_local_files()

  # Find files set by `use_remote_files()`
  remote_files <- get_option_remote_files()

  # Cache remote files in temporary directory
  if (!is.null(remote_files)) {
    temp_dir            <- file.path(tempdir(), "data")
    remote_files        <- copy_data_files(remote_files, temp_dir)
    remote_files        <- normalizePath(remote_files)
    names(remote_files) <- dir(temp_dir, recursive = TRUE)
  }

  files <- c(local_files, remote_files)

  # Specify full paths in chunk options
  set_option_exercise_files(files)

  invisible(files)
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

  invisible(dest_path)
}

copy_file <- function(from, to, ...) {
  if (is_url(from)) {
    utils::download.file(from, to, ...)
  } else {
    file.copy(from, to, ...)
  }
}

is_system_file <- function(path) {
  if (length(path) > 1) {
    return(vapply(path, is_system_file, logical(1)))
  }
  any(vapply(.libPaths(), grepl, x = path, fixed = TRUE, logical(1)))
}

is_url <- function(path) {
  grepl("^((http|ftp)s?|sftp)://", path)
}