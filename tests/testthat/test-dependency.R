
context("dependency")

test_that("tutor html dependencies can be retreived", {
  dep <- tutor_html_dependency()
  expect_equal(dep$name, "tutor")
})

