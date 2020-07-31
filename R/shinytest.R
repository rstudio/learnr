register_shinytest_inputprocessor <- function() {
  shinytest::registerInputProcesser("learnr.exercise", function(value) {
    # Drop all information from `value` except `code`.
    value <- value["code"]
    paste(capture.output(dput(value)), collapse = "\n")
  })
}
