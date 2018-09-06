
context("safe r call")

test_that("safe() executes code expression directly and programmatically", {
  library(rlang)

  file = tempfile()

  # Direct usage
  safe(cat("1\n", file = file))
  expect_equal(readLines(file), "1")

  # Programmatic usage
  exp <- quote(cat("2\n", file = file))
  safe(!!exp)
  expect_equal(readLines(file), "2")

  x <- "3\n"
  safe(cat(!!x, file = file))
  expect_equal(readLines(file), "3")
})
