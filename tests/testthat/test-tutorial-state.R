
test_that("store works", {
  # First write works
  expect_equal(store_tutorial_cache("myName", c("code", "here"), FALSE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Second write without overwrite is a no-op
  expect_equal(store_tutorial_cache("myName", c("updated", "code"), FALSE), FALSE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Overwrite returns true
  expect_equal(store_tutorial_cache("myName", c("updated", "code"), TRUE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("updated", "code"))

  # clear clears
  expect_warning(clear_exercise_cache_env(), "deprecated")
  expect_equal(length(get_tutorial_cache("exercise")), 0)
})

test_that("get_global works", {
  # If no setup chunk, you'll see NULL.
  expect_equal(get_global_setup(), NULL)

  # If a chunk is empty, its passed-in value is NULL which we convert to an empty
  # string to show that the chunk existed and was empty. This now happens in the
  # knitr hooks with `write_setup_chunk` rather than in a cache helper function.
  expect_equal(store_tutorial_cache("__setup__", "", FALSE), TRUE)
  expect_equal(get_global_setup(), "")

  expect_equal(store_tutorial_cache("__setup__", c("code", "here"), TRUE), TRUE)
  expect_equal(get_global_setup(), c("code\nhere"))
})
