
context("question")

test_that("bad ellipses are found", {
  expect_silent(
    question("title", answer("5", correct = TRUE))
  )
  expect_error(
    question("title", answer("5", correct = TRUE), typ = "auto")
  )
})
