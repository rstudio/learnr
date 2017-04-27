
context("options")

test_that("tutor options set knitr options", {
  tutor_options(exercise.cap = "Caption")
  expect_equal(knitr::opts_chunk$get("exercise.cap"), "Caption")
})

test_that("tutor options don't set knitr options when excluded from the call", {
  tutor_options(exercise.cap = "Caption")
  expect_equal(knitr::opts_chunk$get("exercise.eval"), NULL)
})

