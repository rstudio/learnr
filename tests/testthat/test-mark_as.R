context("mark as")

test_that("correct", {
  ans <- correct()
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, TRUE)
  expect_equal(ans$messages, NULL)
})

test_that("correct passes messages", {
  msg <- quiz_text("**msg**")
  ans <- correct(msg)
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, TRUE)
  expect_equal(ans$messages, msg)

  msgs <- htmltools::tagList(
    quiz_text("**msg 1**"),
    quiz_text("_msg 2_")
  )
  ans <- correct(msgs)
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, TRUE)
  expect_equal(ans$messages, msgs)
})


test_that("incorrect", {
  ans <- incorrect()
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, FALSE)
  expect_equal(ans$messages, NULL)
})

test_that("incorrect passes messages", {
  msg <- quiz_text("**msg**")
  ans <- incorrect(msg)
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, FALSE)
  expect_equal(ans$messages, msg)

  msgs <- htmltools::tagList(
    quiz_text("**msg 1**"),
    quiz_text("_msg 2_")
  )
  ans <- incorrect(msgs)
  expect_s3_class(ans, "learnr_mark_as")
  expect_equal(ans$correct, FALSE)
  expect_equal(ans$messages, msgs)
})
