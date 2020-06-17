test_that("Detection of chained setup cycle works", {
  skip_on_cran()
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "setup-cycle.Rmd")),
    "dataA => dataC => dataB => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "setup-cycle-self.Rmd")),
    "dataA => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "setup-cycle-two.Rmd")),
    "dataA => dataB => dataA",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "exercise-cycle.Rmd")),
    "data1 => data3 => data2 => data1",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "exercise-cycle-self.Rmd")),
    "data1 => data1",
    fixed = TRUE
  )
  expect_error(
    rmarkdown::run(test_path("setup-chunks", "exercise-cycle-two.Rmd")),
    "data1 => data2 => data1",
    fixed = TRUE
  )
})
