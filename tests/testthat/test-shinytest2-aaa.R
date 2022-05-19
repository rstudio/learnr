# https://github.com/rstudio/shinytest2/blob/c29b78e9/tests/testthat/test-aaa.R
skip_on_cran() # Uses chromote

# Try to warm up chromote. IDK why it fails on older versions of R.
test_that("Chromote loads", {
  on_ci <- isTRUE(as.logical(Sys.getenv("CI")))
  skip_if(!on_ci, "Not on CI")

  # Wrap in a `try()` as the test doesn't matter
  # Only the action of trying to open chromote matters
  try({
    chromote <- utils::getFromNamespace("default_chromote_object", "chromote")()
    chromote$new_session()
  })

  expect_true(TRUE)
})
