
context("duplicate_env")

test_that("it duplicates", {

  e <- new.env(parent = baseenv())
  e$x <- 1
  e$.key <- "value"

  new_envir <- duplicate_env(e)

  # check parent is equivalent
  expect_true(identical(parent.env(new_envir), baseenv()))

  # check keys exist
  test_names <- c("x", ".key")
  envir_names <- ls(envir = new_envir, all.names = TRUE)
  expect_equal(sort(test_names), sort(envir_names))
})

test_that("does not fail when the envir has a class", {
  e <- new.env()
  e$x <- 1
  class(e) <- "foo"

  expect_error({
    as.list(e)
  })

  expect_silent({
    new_envir <- duplicate_env(e)
  })

  expect_equal(new_envir$x, 1)
})
