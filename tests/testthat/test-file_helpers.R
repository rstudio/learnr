default_opts <- knitr::opts_chunk$get()

test_that("use_remote_files()", {
  use_remote_files(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr")
  )
  expect_equal(
    get_option_remote_files(),
    system.file("examples", "knitr-minimal.Rnw", package = "knitr")
  )

  use_remote_files("https://covidtracking.com/api/v1/states/daily.csv")
  expect_equal(
    get_option_remote_files(),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )

  result <- c(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )

  use_remote_files(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )
  expect_equal(get_option_remote_files(), result)

  use_remote_files(
    c(
      system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
      "https://covidtracking.com/api/v1/states/daily.csv"
    )
  )
  expect_equal(get_option_remote_files(), result)

  names(result) <- c("x.Rnw", "y.csv")

  use_remote_files(
    "x.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "y.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
  )
  expect_equal(get_option_remote_files(), result)

  use_remote_files(
    c(
      "x.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
      "y.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
    )
  )
  expect_equal(get_option_remote_files(), result)

  expect_error(use_remote_files("R/file_helpers.R"), "must be either URLs or")
})

knitr::opts_chunk$restore(default_opts)
