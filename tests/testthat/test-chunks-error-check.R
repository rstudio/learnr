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