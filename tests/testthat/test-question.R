
context("question")

test_that("bad ellipses are found", {
  expect_silent(
    question("title", answer("5", correct = TRUE))
  )
  expect_error(
    expect_warning(
      question("title", answer("5", correct = TRUE), typ = "auto"),
      "had unexpected names: typ"
    ),
    "tutorial_question_answer"
  )
})
