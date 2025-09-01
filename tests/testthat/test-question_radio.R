test_that("question_radio() throws an error when using only answer_fn() answers", {
  expect_error(
    question_radio(
      "test",
      answer_fn(~"one"),
      answer_fn(~"two")
    )
  )
})

test_that("question_radio() throws an error if it doesn't include a correct answer, even with answer_fn()", {
  expect_error(
    question_radio(
      "test",
      answer_fn(~"one"),
      answer("two", correct = FALSE)
    )
  )

  expect_error(
    question_radio(
      "test",
      answer("two", correct = FALSE)
    )
  )
})

test_that("question_radio() warns when using answer_fn() answers", {
  expect_warning(
    q_fn <- question_radio(
      "test",
      answer_fn(~"one"),
      answer("two", correct = TRUE)
    )
  )

  q_no_fn <- question_radio(
    "test",
    answer("two", correct = TRUE)
  )

  clean_question <- function(q) {
    # strip random bits
    q$ids <- NULL
    q$seed <- 42L
    q$answers[[1]]$id <- "answer-id"
    q
  }

  expect_equal(clean_question(q_fn), clean_question(q_no_fn))
})
