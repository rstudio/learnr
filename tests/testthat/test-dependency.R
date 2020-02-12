
context("dependency")

test_that("tutor html dependencies can be retreived", {
  dep <- tutorial_html_dependency()
  expect_equal(dep$name, "tutorial")
})

test_that("tutorial package dependencies can be enumerated", {
  packages <- tutorial_package_dependencies("ex-data-summarise", "learnr")
  expect_true("tidyverse" %in% packages)
})
test_that("Per package, tutorial package dependencies can be enumerated", {
  packages <- tutorial_package_dependencies(package = "learnr")
  expect_true("tidyverse" %in% packages)
})
