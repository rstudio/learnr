default_opts      <- knitr::opts_chunk$get()
temp_dir          <- tempdir()
daily.csv         <- "https://covidtracking.com/api/v1/states/daily.csv"
knitr_minimal.Rnw <- system.file(
  "examples", "knitr-minimal.Rnw", package = "knitr"
)

test_that("use_remote_files()", {
  use_remote_files("https://covidtracking.com/api/v1/states/daily.csv")
  expect_equal(
    get_option_remote_files(),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )

  knitr::opts_chunk$restore(default_opts)
  use_remote_files(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr")
  )
  expect_equal(
    get_option_remote_files(),
    system.file("examples", "knitr-minimal.Rnw", package = "knitr")
  )

  result <- c(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )

  # Test that additional calls add to existing list
  use_remote_files("https://covidtracking.com/api/v1/states/daily.csv")
  expect_equal(get_option_remote_files(), result)

  knitr::opts_chunk$restore(default_opts)
  use_remote_files(
    system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "https://covidtracking.com/api/v1/states/daily.csv"
  )
  expect_equal(get_option_remote_files(), result)

  knitr::opts_chunk$restore(default_opts)
  use_remote_files(
    c(
      system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
      "https://covidtracking.com/api/v1/states/daily.csv"
    )
  )
  expect_equal(get_option_remote_files(), result)

  names(result) <- c("x.Rnw", "y.csv")

  knitr::opts_chunk$restore(default_opts)
  use_remote_files(
    "x.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
    "y.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
  )
  expect_equal(get_option_remote_files(), result)

  knitr::opts_chunk$restore(default_opts)
  use_remote_files(
    c(
      "x.Rnw" = system.file("examples", "knitr-minimal.Rnw", package = "knitr"),
      "y.csv" = "https://covidtracking.com/api/v1/states/daily.csv"
    )
  )
  expect_equal(get_option_remote_files(), result)

  expect_error(use_remote_files("R/file_helpers.R"), "must be either URLs or")
})

test_that("copy_file()", {
  temp_dir <- tempdir()

  copy_file(knitr_minimal.Rnw, file.path(temp_dir, "knitr_minimal.Rnw"))
  expect_equal(
    readLines(knitr_minimal.Rnw),
    readLines(file.path(temp_dir, "knitr_minimal.Rnw"))
  )

  copy_file(daily.csv, file.path(temp_dir, "daily.csv"))
  expect_equal(
    readLines(daily.csv),
    readLines(file.path(temp_dir, "daily.csv"))
  )
})

unlink(temp_dir, recursive = TRUE)
knitr::opts_chunk$restore(default_opts)
