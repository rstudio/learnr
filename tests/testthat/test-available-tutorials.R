
context("available tutorials")

test_that("Tutorial names are retrieved", {

  expect_error(available_tutorials("not a package"), "No package found")
  expect_error(available_tutorials("base"), "No tutorials found")
  expect_true("hello" %in% available_tutorials("learnr")$name)
  expect_true("hello" %in% suppressMessages(run_tutorial(package = "learnr")$name))
  expect_s3_class(available_tutorials("learnr"), "learnr_available_tutorials")

  expect_error(run_tutorial("helloo", package = "learnr"), "\"hello\"")
  expect_error(run_tutorial("doesn't exist", package = "learnr"), "Available ")
  expect_message(run_tutorial(package = "learnr"), "Available ")


  expect_output(
    fixed = TRUE,
    print(available_tutorials("learnr")),
"Available tutorials:\n* learnr\n  - hello         : \"Hello, Tutorial!\"\n  - question_type : \"Question Types in Learnr\"\n  - slidy         : \"Slidly demo\""
  )

})
