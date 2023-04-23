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
  expect_match(ans$messages, "yes", fixed = TRUE)

  # below lower bound
  ans <- question_is_correct(q, 0)
  expect_false(ans$correct)
  expect_match(ans$messages, "at least 1", fixed = TRUE)

  # above upper bound
  ans <- question_is_correct(q, 3.5)
  expect_false(ans$correct)
  expect_match(ans$messages, "at most 2", fixed = TRUE)

  # above upper bound and specifically wrong
  ans <- question_is_correct(q, 3)
  expect_false(ans$correct)
  expect_match(ans$messages, "three", fixed = TRUE)

  # within bound and specifically wrong
  ans <- question_is_correct(q, 1.2)
  expect_false(ans$correct)
  expect_match(ans$messages, "one two", fixed = TRUE)
})

test_that("question_numeric() checks inputs", {
  expect_error(question_numeric("test"), "one correct answer")
  expect_error(question_numeric("test", answer(1, TRUE), value = "3"), "value")
  expect_error(question_numeric("test", answer(1, TRUE), min = "3"), "min")
  expect_error(question_numeric("test", answer(1, TRUE), max = FALSE), "max")
  expect_error(question_numeric("test", answer(1, TRUE), step = -1), "step")
  expect_error(question_numeric("test", answer(1, TRUE), step = Inf), "step")
})

test_that("question_numeric() with tolerance", {
  q <- question_numeric(
    "learnr_numeric",
    answer(6, message = "was 6"),
    answer(5, correct = TRUE, message = "was 5"),
    answer(10, correct = FALSE, message = "was 10"),
    tolerance = 2
  )

  expect_error(question_is_correct(q, "boom"), "number")

  expect_marked_as(question_is_correct(q, 3), TRUE, quiz_text("was 5"))

  # masked by tolerance around 6
  expect_marked_as(question_is_correct(q, 5), FALSE, quiz_text("was 6"))

  # upper bound of tolerance
  expect_marked_as(question_is_correct(q, 8), FALSE, quiz_text("was 6"))

  expect_marked_as(question_is_correct(q, 11), FALSE, quiz_text("was 10"))

  expect_marked_as(question_is_correct(q, 10 + 2.1), FALSE)
})

test_that("question_numeric() with answer functions work", {
  q <- question_numeric(
    "test numeric",
    answer_fn(function(value) {
      if (value %% 2 == 0) {
        correct("even")
      } else if (value %% 2 == 1) {
        incorrect("odd")
      }
    })
  )

  expect_marked_as(question_is_correct(q, 42), TRUE, "even")
  expect_marked_as(question_is_correct(q, 21), FALSE, "odd")
  expect_marked_as(question_is_correct(q, 0.1), FALSE)
})

test_that("question_numeric() with function and literal answers", {
  q <- question_numeric(
    "test numeric",
    answer(4321, TRUE, 'magic'),
    answer_fn(function(value) {
      if (value %% 2 == 0) {
        correct("even")
      } else if (value %% 2 == 1) {
        incorrect("odd")
      }
    }),
    answer(2.1, FALSE, "after")
  )

  expect_marked_as(question_is_correct(q, 4321), TRUE, quiz_text("magic"))
  expect_marked_as(question_is_correct(q, 42), TRUE, "even")
  expect_marked_as(question_is_correct(q, 21), FALSE, "odd")
  expect_marked_as(question_is_correct(q, 2.1), FALSE, quiz_text("after"))
  expect_marked_as(question_is_correct(q, 0.1), FALSE) # fallback
})
