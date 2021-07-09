copy_data_dir <- function(source_dir, exercise_dir) {
  if (is.null(source_dir)) {
    # First check options(), then environment variable, then default to "data/"
    source_dir <- getOption(
      "tutorial.data_dir",
      Sys.getenv("TUTORIAL_DATA_DIR", if (dir.exists("data")) "data" else "")
    )
  }

  if (identical(source_dir, "")) {
    return(invisible(NULL))
  }

  if (!dir.exists(source_dir)) {
    rlang::abort(
      "An error occurred with the tutorial: the data directory does not exist.",
      class = "learnr_missing_source_data_dir"
    )
  }

  dest_dir <- file.path(exercise_dir, "data")
  dir.create(dest_dir)

  if (!dir.exists(dest_dir)) {
    rlang::abort(
      "An error occurred with the tutorial: we weren't able to create the data directory for this exercise.",
      class = "learnr_missing_dest_data_dir"
    )
  }

  file.copy(dir(source_dir, full.names = TRUE), dest_dir, recursive = TRUE)

  return(invisible(dest_dir))
}
