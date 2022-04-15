
context("available tutorials")

test_that("Tutorial names are retrieved", {
  local_edition(3)

  expect_error(available_tutorials("not a package"), "No package found")
  expect_error(available_tutorials("base"), "No tutorials found")
  expect_true("hello" %in% available_tutorials("learnr")$name)
  expect_true("hello" %in% suppressMessages(run_tutorial(package = "learnr")$name))
  expect_s3_class(available_tutorials("learnr"), "learnr_available_tutorials")

  expect_error(run_tutorial("helloo", package = "learnr"), "\"hello\"")
  expect_error(run_tutorial("doesn't exist", package = "learnr"), "Available ")
  expect_message(run_tutorial(package = "learnr"), "Available ")

  expect_snapshot(available_tutorials("learnr"))
})
