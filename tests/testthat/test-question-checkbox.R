

context("question-checkbox")

test_that("correct messages are not included", {

  q <- question(
    "test",
    answer("A", correct = TRUE, message = "msg **1**"),
    answer("B", correct = TRUE, message = "msg _2_"),
    answer("C", correct = FALSE, message = "msg **3**"),
    answer("D", correct = FALSE, message = "msg _4_"),
    answer("E", correct = FALSE, message = "msg **5**")
  )

  ans <- question_is_correct(q, c("A", "B", "C"))

  expect_equivalent(ans$correct, FALSE)
  expect_equivalent(as.character(ans$messages), "msg <strong>3</strong>")


  ans <- question_is_correct(q, c("A", "B", "C", "D"))
  expect_equivalent(ans$correct, FALSE)
  expect_equivalent(as.character(ans$messages), "msg <strong>3</strong>\nmsg <em>4</em>")


  ans <- question_is_correct(q, c("A"))
  expect_equivalent(ans$correct, FALSE)
  expect_equivalent(ans$messages, NULL)

  ans <- question_is_correct(q, c("A", "B"))
  expect_equivalent(ans$correct, TRUE)
  expect_equivalent(as.character(ans$messages), "msg <strong>1</strong>\nmsg <em>2</em>")

})
