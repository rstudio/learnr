test_that("question_numeric() correctly grades a question", {
  q <- question_numeric(
    "learnr_numeric",
    answer(1.234, correct = TRUE, message = "yes"),
    answer(1.2, message = "one two"),
    answer(3, message = "three"),
    min = 1,
    max = 2,
    step = 0.1
  )

  # correct
  ans <- question_is_correct(q, 1.234)
  expect_true(ans$correct)
  expect_match(ans$message, "yes", fixed = TRUE)

  # below lower bound
  ans <- question_is_correct(q, 0)
  expect_false(ans$correct)
  expect_match(ans$message, "at least 1", fixed = TRUE)

  # above upper bound
  ans <- question_is_correct(q, 3.5)
  expect_false(ans$correct)
  expect_match(ans$message, "at most 2", fixed = TRUE)

  # above upper bound and specifically wrong
  ans <- question_is_correct(q, 3)
  expect_false(ans$correct)
  expect_match(ans$message, "three", fixed = TRUE)

  # within bound and specifically wrong
  ans <- question_is_correct(q, 1.2)
  expect_false(ans$correct)
  expect_match(ans$message, "one two", fixed = TRUE)
})

test_that("question_numeric() checks inputs", {
  expect_error(question_numeric("test"), "one correct answer")
  expect_error(question_numeric("test", answer(1, TRUE), value = "3"), "value")
  expect_error(question_numeric("test", answer(1, TRUE), min = "3"), "min")
  expect_error(question_numeric("test", answer(1, TRUE), max = FALSE), "max")
  expect_error(question_numeric("test", answer(1, TRUE), step = -1), "step")
  expect_error(question_numeric("test", answer(1, TRUE), step = Inf), "step")
})
