test_that("run_tutorial() with bad inputs", {
  expect_error(
    run_tutorial("helloo"),
    "Could not find"
  )
  expect_error(
    run_tutorial("helloo", package = "learnr"),
    "Did you mean \"hello\""
  )
  expect_error(
    run_tutorial("doesn't exist", package = "learnr"),
    "Available "
  )

  expect_error(run_tutorial(letters[1:3]))
  expect_error(run_tutorial(package = letters[1:3]))
})

test_that("validating and finding tutorials", {
  # value when nothing is provided
  expect_equal(run_validate_tutorial_dir(NULL), list(valid = FALSE, dir = NULL))
  expect_equal(run_validate_tutorial_file(NULL), list(valid = FALSE, dir = NULL))
  expect_equal(run_validate_tutorial_path(NULL), list(valid = FALSE, dir = NULL))

  # returns name if not an existing file
  expect_equal(run_validate_tutorial_dir("foo"), list(valid = FALSE, dir = "foo"))
  expect_equal(run_validate_tutorial_file("foo"), list(valid = FALSE, dir = "foo"))
  expect_equal(run_validate_tutorial_path("foo"), list(valid = FALSE, dir = "foo"))
  expect_null(run_find_tutorial_rmd("foo"))

  tmpdir <- tempfile()
  withr::defer(unlink(tmpdir, recursive = TRUE))
  expect_equal(
    run_validate_tutorial_path(tmpdir),
    list(valid = FALSE, dir = tmpdir)
  )
  expect_equal(
    run_validate_tutorial_dir(tmpdir),
    list(valid = FALSE, dir = tmpdir)
  )
  expect_equal(
    run_validate_tutorial_file(tmpdir),
    list(valid = FALSE, dir = tmpdir)
  )
  expect_null(run_find_tutorial_rmd(tmpdir))

  # returns error if it's a directory without any Rmds
  dir.create(tmpdir)
  tmpdir_norm <- normalizePath(tmpdir)
  expect_error(run_validate_tutorial_path(tmpdir), "No R Markdown files")
  expect_error(run_validate_tutorial_dir(tmpdir), "No R Markdown files")
  expect_equal(
    run_validate_tutorial_file(tmpdir),
    list(valid = FALSE, dir = tmpdir)
  )
  expect_null(run_find_tutorial_rmd(tmpdir))

  # returns directory if it exists with one tutorial
  writeLines(
    c("---", "runtime: shiny_prerendered", "---"),
    file.path(tmpdir, "one.Rmd")
  )
  expect_equal(
    run_validate_tutorial_path(tmpdir),
    list(valid = TRUE, dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_dir(tmpdir),
    list(valid = TRUE, dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_file(tmpdir),
    list(valid = FALSE, dir = tmpdir)
  )
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "one.Rmd")),
    list(valid = TRUE, file = "one.Rmd", dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_path(file.path(tmpdir, "one.Rmd")),
    run_validate_tutorial_file(file.path(tmpdir, "one.Rmd"))
  )
  expect_equal(run_find_tutorial_rmd(tmpdir), "one.Rmd")

  # returns directory if more than one Rmd but one is clearly a tutorial
  file.create(file.path(tmpdir, "two.Rmd"))
  expect_equal(
    run_validate_tutorial_dir(tmpdir),
    list(valid = TRUE, dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_dir(tmpdir),
    run_validate_tutorial_path(tmpdir)
  )
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "two.Rmd")),
    list(valid = FALSE, dir = file.path(tmpdir, "two.Rmd"))
  )
  expect_equal(run_find_tutorial_rmd(tmpdir), "one.Rmd")

  # returns error if there's more than one tutorial in that directory
  writeLines(
    c("---", "runtime: shiny_prerendered", "---"),
    file.path(tmpdir, "two.Rmd")
  )
  expect_error(run_validate_tutorial_dir(tmpdir), "multiple R Markdown files")
  expect_error(run_validate_tutorial_path(tmpdir), "multiple R Markdown files")
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "two.Rmd")),
    list(valid = TRUE, file = "two.Rmd", dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "two.Rmd")),
    list(valid = TRUE, file = "two.Rmd", dir = tmpdir_norm)
  )
  expect_null(run_find_tutorial_rmd(tmpdir))

  # returns valid if directory has an index.Rmd file
  writeLines(
    c("---", "runtime: shiny_prerendered", "---"),
    file.path(tmpdir, "index.Rmd")
  )
  expect_equal(
    run_validate_tutorial_dir(tmpdir),
    list(valid = TRUE, dir = normalizePath(tmpdir))
  )
  expect_equal(
    run_validate_tutorial_path(tmpdir),
    list(valid = TRUE, dir = normalizePath(tmpdir))
  )
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "two.Rmd")),
    list(valid = TRUE, file = "two.Rmd", dir = tmpdir_norm)
  )
  expect_equal(
    run_validate_tutorial_file(file.path(tmpdir, "index.Rmd")),
    list(valid = TRUE, file = "index.Rmd", dir = tmpdir_norm)
  )
  expect_equal(run_find_tutorial_rmd(tmpdir), "index.Rmd")
})


# Safe --------------------------------------------------------------------

test_that("safe() executes code expression directly and programmatically", {
  skip_on_covr()
  skip_if_not_installed("rlang")

  library(rlang)

  file <- tempfile()

  # Direct usage
  safe(cat("1\n", file = !!file))
  expect_equal(readLines(file), "1")

  # Programmatic usage
  exp <- expr(cat("2\n", file = !!file))
  safe(!!exp)
  expect_equal(readLines(file), "2")

  x <- "3\n"
  safe(cat(!!x, file = !!file))
  expect_equal(readLines(file), "3")
})

