
context("question")

test_that("bad ellipses are found", {
  expect_silent(
    question("title", answer("5", correct = TRUE))
  )
  expect_error(
    question("title", answer("5", correct = TRUE), typ = "auto")
  )
})

test_that("loading placeholder is correctly generated for HTML question texts", {
  expect_silent(
    q1 <- question(htmltools::tags$p("Did this work?"), answer("yes", correct = TRUE))
  )

  expect_silent(
    q2 <- question(htmltools::HTML("<p>Did this work?</p>"), answer("yes", correct = TRUE))
  )

  expect_equal(q1$loading, q2$loading)
})