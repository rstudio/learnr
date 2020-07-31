register_shinytest_inputprocessor <- function() {
  if (is_installed("shinytest", "1.4.0.9002")) {
    shinytest::registerInputProcessor("learnr.exercise", function(value) {
      # Drop all information from `value` except `code`.
      value <- value["code"]
      dput_to_string(value)
    })
  }
}
