test_that("tutorial() returns an rmarkdown format", {
  expect_true(inherits(tutorial(), "rmarkdown_output_format"))
})

test_that("tutorial() does not support anchor_sections", {
  expect_error(tutorial(anchor_sections = TRUE), "do not support")
  expect_error(tutorial(anchor_sections = FALSE), "do not support")
})
