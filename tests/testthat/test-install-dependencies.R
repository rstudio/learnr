context("install tutorial dependencies")

create_test_tutorial <- function(code) {
  tutorial_dir <- file.path(tempdir(), "tutorial-deps")
  dir.create(tutorial_dir)
  tutorial_path <- tempfile("tutorial-deps",
                            tmpdir = tutorial_dir,
                            fileext = ".R")
  writeLines(code, con = tutorial_path)
  invisible(tutorial_dir)
}

test_that("tutorial dependency check works (interactive)", {
  skip_if_not(interactive())

  tutorial_dir <- create_test_tutorial("library(pkg1)\npkg2::n()")
  on.exit(unlink(tutorial_dir, recursive = TRUE), add = TRUE)

  expect_equal(
    with_mock(
      menu = function(title, choices) 1,
      install.packages = function(pkgs) "mock install",
      install_tutorial_dependencies(tutorial_dir)
    ),
    "mock install"
  )

  expect_error(
    with_mock(
      menu = function(title, choices) 2,
      install_tutorial_dependencies(tempdir())
    )
  )
})

test_that("tutorial dependency check works (not interactive)", {
  skip_if(interactive())

  tutorial_dir <- create_test_tutorial("library(pkg1)\npkg2::n()")
  on.exit(unlink(tutorial_dir, recursive = TRUE), add = TRUE)

  expect_error(
    with_mock(
      menu = function(title, choices) 2,
      install_tutorial_dependencies(tutorial_dir)
    )
  )
})

test_that("tutorial dependency check returns NULL for no dependencies", {

  tutorial_dir <- create_test_tutorial("sum(1:3)")
  on.exit(unlink(tutorial_dir, recursive = TRUE), add = TRUE)

  expect_silent(install_tutorial_dependencies(tutorial_dir))
})
