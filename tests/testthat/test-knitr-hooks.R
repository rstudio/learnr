test_that("Error thrown: has -check chunk but missing exercise.checker", {
  rmd <- test_path("tutorials", "missing-exercise-checker.Rmd")

  withr::with_tempfile("outfile", fileext = ".html", {
    expect_error(
      rmarkdown::render(rmd, output_file = outfile, quiet = TRUE),
      regexp = "exercise checker function is not configured"
    )
  })
})

test_that("*-error-check chunks require *-check chunks", {
  skip_if_not(rmarkdown::pandoc_available())

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
  skip_if_not(rmarkdown::pandoc_available())

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
