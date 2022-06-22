test_that("no message-correct", {

  q <- question(
    "test",
    answer("A", correct = TRUE),
    answer("B", correct = FALSE),
    correct = "test-correct",
    incorrect = "test-incorrect"
  )

  ans <- question_is_correct(q, c("A"))

  out <- question_messages(q, ans$messages, ans$correct, (!isTRUE(q$allow_retry)) || ans$correct)

  expect_s3_class(out, "shiny.tag.list")
  expect_equivalent(as.character(out[[1]]$children[[1]]), "test-correct")
  expect_true(is.null(out$children[[2]]))
  expect_true(is.null(out$children[[3]]))

})


test_that("no message-incorrect", {

  q <- question(
    "test",
    answer("A", correct = TRUE),
    answer("B", correct = FALSE),
    correct = "test-correct",
    incorrect = "test-incorrect"
  )

  ans <- question_is_correct(q, c("B"))

  out <- question_messages(q, ans$messages, ans$correct, (!isTRUE(q$allow_retry)) || ans$correct)

  expect_s3_class(out, "shiny.tag.list")
  expect_equivalent(as.character(out[[1]]$children[[1]]), "test-incorrect")
  expect_true(is.null(out$children[[2]]))
  expect_true(is.null(out$children[[3]]))

})


test_that("all messages-correct", {

  q <- question(
    "test",
    answer("A", correct = TRUE, message = "msg **1**"),
    answer("B", correct = FALSE, message = "msg _2_"),
    correct = "test-correct",
    incorrect = "test-incorrect",
    message = "test-message",
    post_message = "test-post"
  )

  ans <- question_is_correct(q, c("A"))

  out <- question_messages(q, ans$messages, ans$correct, (!isTRUE(q$allow_retry)) || ans$correct)

  expect_s3_class(out, "shiny.tag.list")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[1]]), "test-correct")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[3]]), "msg <strong>1</strong>")
  expect_equivalent(as.character(out[[2]]$children[[1]]), "test-message")
  expect_equivalent(as.character(out[[3]]$children[[1]]), "test-post")

})

test_that("all messages-incorrect", {

  q <- question(
    "test",
    answer("A", correct = TRUE, message = "msg **1**"),
    answer("B", correct = FALSE, message = "msg _2_"),
    correct = "test-correct",
    incorrect = "test-incorrect",
    message = "test-message",
    post_message = "test-post"
  )

  ans <- question_is_correct(q, c("B"))

  out <- question_messages(q, ans$messages, ans$correct, (!isTRUE(q$allow_retry)) || ans$correct)

  expect_s3_class(out, "shiny.tag.list")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[1]]), "test-incorrect")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[3]]), "msg <em>2</em>")
  expect_equivalent(as.character(out[[2]]$children[[1]]), "test-message")
  expect_equivalent(as.character(out[[3]]$children[[1]]), "test-post")

})



test_that("custom message", {

  q <- question(
    "test",
    answer("A", correct = TRUE, message = htmltools::tags$div("_Test_")),
    answer("B", correct = FALSE),
    correct = "test-correct",
    incorrect = "test-incorrect"
  )

  ans <- question_is_correct(q, c("A"))

  out <- question_messages(q, ans$messages, ans$correct, (!isTRUE(q$allow_retry)) || ans$correct)

  expect_s3_class(out, "shiny.tag.list")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[1]]), "test-correct")
  expect_equivalent(as.character(out[[1]]$children[[1]][[1]][[3]]$children), "_Test_")
  expect_true(is.null(out$children[[2]]))
  expect_true(is.null(out$children[[3]]))

})

test_that("answer options must have unique values (option)", {
  expect_error(
    answer_values(list(answers = list(
      answer("same"),
      answer("same")
    )))
  )
})

test_that("answer functions", {
  # Test various ways of specifying the answer function
  answer <- answer_fn(identity, label = "test `answer_fn()`")
  expect_true(eval(parse(text = answer$value))(TRUE))

  # test properties on this first answer object
  expect_equal(answer$type, "function")
  expect_equal(answer$label, quiz_text("test `answer_fn()`"))
  expect_null(answer$correct)
  expect_null(answer$message)

  answer <- answer_fn(function(x) identity(x))
  expect_true(eval(parse(text = answer$value))(TRUE))

  answer <- answer_fn(~ identity(.x))
  expect_true(eval(parse(text = answer$value))(TRUE))

  answer <- answer_fn("identity")
  expect_true(eval(parse(text = answer$value))(TRUE))

  expect_error(answer_fn(function() "FAIL"))
  expect_error(answer_fn("FAIL"))

  answer <-
    local({
      # PASS won't be defined when we evaluate the re-parsed fn body
      PASS <- function(x) TRUE
      answer_fn("PASS")
    })
  expect_true(eval(parse(text = answer$value))())
})

test_that("answer functions: filtering and splitting", {
  q <- question_text(
    "test question",
    answer("apple", TRUE, "correct"),
    answer_fn(function(x) "F1", "f1"),
    answer("banana", FALSE, "incorrect"),
    answer_fn(~ "F2", "f2"),
    answer("mango", FALSE, "also incorrect")
  )

  expect_equal(
    answer_type_is_function(q$answers),
    c(FALSE, TRUE, FALSE, TRUE, FALSE)
  )

  expect_equal(length(answers_split_type(q$answers)[["literal"]]), 3L)
  expect_equal(length(answers_split_type(q$answers)[["function"]]), 2L)

  expect_equal(
    unlist(answer_labels(q)),
    c("apple", "f1", "banana", "f2", "mango")
  )

  expect_equal(
    unlist(answer_labels(q, exclude_answer_fn = TRUE)),
    c("apple", "banana", "mango")
  )

  expect_equal(
    unlist(answer_values(q, exclude_answer_fn = TRUE)),
    c("apple", "banana", "mango")
  )

  q_labels <- unlist(answer_values(q))
  expect_match(q_labels[2], "function.+F1")
  expect_match(q_labels[4], "function.+F2")
})

test_that("mark_as(), correct(), incorrect()", {
  expect_equal(
    mark_as(TRUE, "correct message"),
    correct("correct message")
  )

  expect_equal(
    mark_as(FALSE, "incorrect message"),
    incorrect("incorrect message")
  )

  expect_s3_class(mark_as(TRUE, "correct"), "learnr_mark_as")
  expect_s3_class(correct("correct"), "learnr_mark_as")
  expect_s3_class(incorrect("incorrect"), "learnr_mark_as")
})
