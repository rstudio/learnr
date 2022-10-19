test_that("Error thrown: has -check chunk but missing exercise.checker", {
  skip_if_not_pandoc("1.14")

  rmd <- test_path("tutorials", "missing-exercise-checker.Rmd")

  withr::with_tempfile("outfile", fileext = ".html", {
    expect_error(
      rmarkdown::render(rmd, output_file = outfile, quiet = TRUE),
      regexp = "exercise checker function is not configured"
    )
  })
})

test_that("*-error-check chunks require *-check chunks", {
  skip_if_not_pandoc("1.14")

  tmpfile <- tempfile(fileext = ".html")
  on.exit(unlink(tmpfile))

  expect_error(
    rmarkdown::render(test_path("setup-chunks", "error-check-chunk_bad.Rmd"), output_file = tmpfile, quiet = TRUE),
    "ex-check",
    fixed = TRUE
  )

  expect_silent(
    rmarkdown::render(test_path("setup-chunks", "error-check-chunk_good.Rmd"), output_file = tmpfile, quiet = TRUE)
  )
})

test_that("Detection of chained setup cycle works", {
  skip_if_not_pandoc("1.14")

  tmpfile <- tempfile(fileext = ".html")
  on.exit(unlink(tmpfile))

  expect_error(
    rmarkdown::render(test_path("setup-chunks", "setup-cycle.Rmd"), output_file = tmpfile, quiet = TRUE),
    "dataA => dataC => dataB => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "setup-cycle-self.Rmd"), output_file = tmpfile, quiet = TRUE),
    "dataA => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "setup-cycle-two.Rmd"), output_file = tmpfile, quiet = TRUE),
    "dataA => dataB => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "exercise-cycle-default-setup.Rmd"), output_file = tmpfile, quiet = TRUE),
    "data1 => data1-setup => data1",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "exercise-cycle.Rmd"), output_file = tmpfile, quiet = TRUE),
    "data1 => data3 => data2 => data1",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "exercise-cycle-self.Rmd"), output_file = tmpfile, quiet = TRUE),
    "data1 => data1",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::render(test_path("setup-chunks", "exercise-cycle-two.Rmd"), output_file = tmpfile, quiet = TRUE),
    "data1 => data2 => data1",
    fixed = TRUE
  )
})

test_that("Empty exercise code still creates an exercise", {
  skip_if_not_pandoc("1.14")
  local_edition(3)

  # empty and full exercises are the same, except that "full" has empty lines
  # in the exercise chunk. They should result in identical exercises.
  rmd_empty <- test_path("tutorials", "knitr-hooks_empty-exercise", "empty-exercise.Rmd")
  rmd_full <- test_path("tutorials", "knitr-hooks_empty-exercise", "full-exercise.Rmd")

  ex_empty <- get_tutorial_exercises(rmd_empty)
  ex_full <- get_tutorial_exercises(rmd_full)

  # One small difference that doesn't matter at all...
  ex_full$empty$options$code <- NULL

  expect_equal(ex_empty, ex_full)
})

test_that("Empty exercises with duplicate labels throw an error", {
  skip_if_not_pandoc("1.14")
  local_edition(3)

  rmd <- test_path("tutorials", "knitr-hooks_empty-exercise", "duplicate-label.Rmd")
  expect_error(expect_message(get_tutorial_exercises(rmd), "duplicate"))
})
