test_that("question_checkbox() does not include correct messages for incorrect answer", {
  q <- question_checkbox(
    "test",
    answer("A", correct = TRUE, message = "msg **1**"),
    answer("B", correct = TRUE, message = "msg _2_"),
    answer("C", correct = FALSE, message = "msg **3**"),
    answer("D", correct = FALSE, message = "msg _4_"),
    answer("E", correct = FALSE, message = "msg **5**"),
    answer("F", correct = FALSE)
  )

  ans <- question_is_correct(q, c("A", "B", "C"))

  expect_marked_as(ans, correct = FALSE, messages = quiz_text("msg **3**"))

  ans <- question_is_correct(q, c("A", "B", "C", "D"))
  expect_marked_as(
    ans,
    correct = FALSE,
    messages = list(quiz_text("msg **3**"), quiz_text("msg _4_"))
  )

  ans <- question_is_correct(q, c("A"))
  expect_marked_as(ans, correct = FALSE, messages = NULL)

  ans <- question_is_correct(q, c("A", "B"))
  expect_marked_as(
    ans,
    correct = TRUE,
    messages = list(quiz_text("msg **1**"), quiz_text("msg _2_"))
  )

  expect_marked_as(question_is_correct(q, "F"), correct = FALSE)
})

test_that("question_checkbox() message depends on whether allow_retry = TRUE", {
  incorrect_message <- "incorrect"
  try_again_message <- "try_again"

  q <- question_checkbox(
    "test",
    answer("A", correct = TRUE),
    answer("B", correct = TRUE),
    answer("C", correct = FALSE),
    incorrect = incorrect_message,
    try_again = try_again_message
  )

  out_no_retry <- question_messages(
    question = q,
    messages = NULL,
    is_correct = FALSE,
    is_done = TRUE
  )
  expect_equal(as.character(out_no_retry[[1]]$children[[1]]), incorrect_message)

  out_retry <- question_messages(
    question = q,
    messages = NULL,
    is_correct = FALSE,
    is_done = FALSE
  )
  expect_equal(as.character(out_retry[[1]]$children[[1]]), try_again_message)
})

test_that("question_checkbox() evaluates function answers first", {
  q <- question_checkbox(
    "test",
    answer("A", TRUE, "a"),
    answer("B", TRUE, "b"),
    answer("C", FALSE, "c"),
    answer_fn(function(value) {
      if (identical(value, c("B", "C"))) {
        mark_as(FALSE, "B + C is special")
      }
    })
  )

  response <- question_is_correct(q, c("C"))
  expect_marked_as(response, FALSE, quiz_text("c"))

  response <- question_is_correct(q, c("A", "C"))
  expect_marked_as(response, FALSE, quiz_text("c"))

  response <- question_is_correct(q, c("B", "C"))
  expect_marked_as(response, FALSE, "B + C is special")

  response <- question_is_correct(q, c("B", "A"))
  expect_marked_as(response, TRUE, list(quiz_text("a"), quiz_text("b")))
})
