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
