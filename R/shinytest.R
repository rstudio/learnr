# Input processor, for generating code in shinytest Recorder app
register_shinytest_inputprocessor <- function() {
  if (is_installed("shinytest2", "0.1.0")) {
    shinytest2::register_input_processor("learnr.exercise", function(value) {
      # Drop all information from `value` except `code`.
      value <- value["code"]
      dput_to_string(value)
    })
  }
}

# Snapshot preprocessor, for massaging input value before taking snapshot.
snapshotPreprocessorLearnrExercise <- function(value) {
  value$timestamp <- NULL
  value
}
