test_that("*-error-check chunks require *-check chunks", {
  skip_on_cran()
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "error-check-chunk_bad.Rmd"), render_args = list(quiet = TRUE)),
    "ex-check",
    fixed = TRUE
  )

  tmpfile <- tempfile(fileext = ".html")
  on.exit(unlink(tmpfile))
  expect_silent(
    rmarkdown::render(test_path("setup-chunks", "error-check-chunk_good.Rmd"), output_file = tmpfile, quiet = TRUE)
  )
})