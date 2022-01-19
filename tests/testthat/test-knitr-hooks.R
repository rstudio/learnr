test_that("Error thrown: has -check chunk but missing exercise.checker", {
  rmd <- test_path("tutorials", "missing-exercise-checker.Rmd")

  withr::with_tempfile("outfile", fileext = ".html", {
    expect_error(
      rmarkdown::render(rmd, output_file = outfile, quiet = TRUE),
      regexp = "exercise checker function is not configured"
    )
  })
})
