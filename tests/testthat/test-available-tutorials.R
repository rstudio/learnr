
context("available tutorials")

test_that("Tutorial names are retrieved", {
  
  expect_error(available_tutorials("not a package"), "No tutorials found")
  expect_true("hello" %in% available_tutorials("learnr"))
  expect_true("hello" %in% suppressMessages(run_tutorial(package = "learnr")))
  expect_message(run_tutorial(package = "learnr"), "Available ")

})
