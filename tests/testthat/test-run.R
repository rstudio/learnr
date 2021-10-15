test_that("run_tutorial() with bad inputs", {
  expect_error(
    run_tutorial("helloo"),
    "`package` must be provided"
  )
  expect_error(
    run_tutorial(test_path("tutorials", "basic.Rmd")),
    "must be the path to a directory"
  )
  expect_error(
    run_tutorial("helloo", package = "learnr"),
    "\"hello\""
  )
  expect_error(
    run_tutorial("doesn't exist", package = "learnr"),
    "Available "
  )

  expect_error(run_tutorial(letters[1:3]))
  expect_error(run_tutorial(package = letters[1:3]))
})

test_that("validate_tutorial_path_is_dir()", {
  # returns NULL if NULL
  expect_null(validate_tutorial_path_is_dir(NULL)$value)
  expect_equal(validate_tutorial_path_is_dir(NULL), list(valid = FALSE))

  # returns name if not an existing file
  expect_equal(validate_tutorial_path_is_dir("foo"), list(valid = FALSE, value = "foo"))

  tmpdir <- tempfile()
  withr::defer(unlink(tmpdir, recursive = TRUE))
  expect_equal(
    validate_tutorial_path_is_dir(tmpdir),
    list(valid = FALSE, value = tmpdir)
  )

  # returns error if it's a directory without any Rmds
  dir.create(tmpdir)
  expect_error(validate_tutorial_path_is_dir(tmpdir), "No R Markdown files")

  # returns directory if it exists with one tutorial
  file.create(file.path(tmpdir, "one.Rmd"))
  expect_equal(
    validate_tutorial_path_is_dir(tmpdir),
    list(valid = TRUE, value = tmpdir)
  )

  # returns error if there's more than one tutorial in that directory
  file.create(file.path(tmpdir, "two.Rmd"))
  expect_error(validate_tutorial_path_is_dir(tmpdir), "Multiple `.Rmd` files")

  # returns valid if directory has an index.Rmd file
  file.create(file.path(tmpdir, "index.Rmd"))
  expect_equal(
    validate_tutorial_path_is_dir(tmpdir),
    list(valid = TRUE, value = tmpdir)
  )
})
