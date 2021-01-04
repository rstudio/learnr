fdbck <- function(message = "a", correct = TRUE, type = NULL, location = NULL) {
  feedback(message, correct, type, location)
}

test_that("feedback_validated() doesn't validate length-0 objects", {
  expect_null(feedback_validated(NULL))
  expect_equal(feedback_validated(list()), list())
})

test_that("feedback must be a list with $message and $correct", {
  expect_error(feedback_validated("no"), "must be a list")
  expect_error(feedback_validated(list(correct = FALSE)), "message")
  expect_error(feedback_validated(list(message = "foo")), "correct")
})

test_that("feedback message must be character or tag or tagList", {
  expect_error(feedback_validated(fdbck(list())), "character")
  expect_error(feedback_validated(fdbck(2)), "character")
  expect_error(feedback_validated(fdbck(list(a = 1, b = 2))), "character")

  expect_silent(feedback_validated(fdbck("good")))
  expect_silent(feedback_validated(fdbck(htmltools::HTML("good"))))
  expect_silent(feedback_validated(fdbck(htmltools::p("good"))))
  expect_silent(feedback_validated(fdbck(htmltools::tagList(htmltools::p("good")))))
})

test_that("feedback type must be one of the acceptable values", {
  expect_error(feedback_validated(fdbck(type = "--bad--")), "type")

  expect_equal(feedback_validated(fdbck(correct = TRUE))$type, "success")
  expect_equal(feedback_validated(fdbck(correct = FALSE))$type, "error")
  expect_equal(feedback_validated(fdbck(type = c("info", "error")))$type, "info")
})

test_that("feedback location must be one of the acceptable values", {
  expect_error(feedback_validated(fdbck(location = "--bad--")), "location")

  expect_equal(feedback_validated(fdbck())$location, "append")
  expect_equal(feedback_validated(fdbck(location = c("replace", "prepend")))$location, "replace")
})
