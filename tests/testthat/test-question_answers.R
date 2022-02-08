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

  expect_s3_class(out, "shiny.tag")
  expect_equivalent(as.character(out$children[[1]]$children[[1]]), "test-correct")
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

  expect_s3_class(out, "shiny.tag")
  expect_equivalent(as.character(out$children[[1]]$children[[1]]), "test-incorrect")
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

  expect_s3_class(out, "shiny.tag")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[1]]), "test-correct")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[3]]), "msg <strong>1</strong>")
  expect_equivalent(as.character(out$children[[2]]$children[[1]]), "test-message")
  expect_equivalent(as.character(out$children[[3]]$children[[1]]), "test-post")

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

  expect_s3_class(out, "shiny.tag")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[1]]), "test-incorrect")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[3]]), "msg <em>2</em>")
  expect_equivalent(as.character(out$children[[2]]$children[[1]]), "test-message")
  expect_equivalent(as.character(out$children[[3]]$children[[1]]), "test-post")

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

  expect_s3_class(out, "shiny.tag")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[1]]), "test-correct")
  expect_equivalent(as.character(out$children[[1]]$children[[1]][[1]][[3]]$children), "_Test_")
  expect_true(is.null(out$children[[2]]))
  expect_true(is.null(out$children[[3]]))

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
