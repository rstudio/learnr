
context("dependency")

test_that("tutor html dependencies can be retreived", {
  dep <- tutorial_html_dependency()
  expect_equal(dep$name, "tutorial")
})

