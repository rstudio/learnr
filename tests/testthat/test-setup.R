
context("setup")

test_that("store works", {
  # First write works
  expect_equal(store_exercise_setup_chunk("myName", c("code", "here"), FALSE), TRUE)
  expect_equal(setup_chunks$myName, c("code", "here"))

  # Second write without overwrite is a no-op
  expect_equal(store_exercise_setup_chunk("myName", c("updated", "code"), FALSE), FALSE)
  expect_equal(setup_chunks$myName, c("code", "here"))

  # Overwrite returns true
  expect_equal(store_exercise_setup_chunk("myName", c("updated", "code"), TRUE), TRUE)
  expect_equal(setup_chunks$myName, c("updated", "code"))

  # clear clears
  clear_exercise_setup_chunks()
  expect_equal(length(ls(envir = setup_chunks)), 0)
})

test_that("get_global works", {
  # If no setup chunk, you'll see NULL.
  expect_equal(get_global_setup(), NULL)

  # If a chunk is empty, its passed-in value is NULL which we convert to an empty
  # string to show that the chunk existed and was empty.
  expect_equal(store_exercise_setup_chunk("__setup__", NULL, FALSE), TRUE)
  expect_equal(get_global_setup(), "")

  expect_equal(store_exercise_setup_chunk("__setup__", c("code", "here"), TRUE), TRUE)
  expect_equal(get_global_setup(), c("code\nhere"))
})