copy_data_dir <- function(source_dir, exercise_dir) {
  if (identical(source_dir, "")) {
    return(invisible(NULL))
  }

  if (!dir.exists(source_dir)) {
    rlang::abort(
      paste("An error occured:",
            "we weren't able to find the data directory for this exercise."),
      class = "learnr.missing_source_dir"
    )
  }

  dest_dir <- file.path(exercise_dir, "data")
  dir.create(dest_dir)

  if (!dir.exists(dest_dir)) {
    rlang::abort(
      paste("An error occurred:",
            "we weren't able to create the data directory for this exercise."),
      class = "learnr.missing_dest_dir"
    )
  }

  file.copy(dir(source_dir, full.names = TRUE), dest_dir, recursive = TRUE)

  return(invisible(dest_dir))
}
