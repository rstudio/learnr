context("Optionally reveal solution")

render_tutorial_with_reveal_solution <- function(opt_string) {
  ex <- readLines(test_path("tutorials", "optional-show-solution.Rmd"))
  ex <- sub("#<<reveal_solution>>", opt_string, ex, fixed = TRUE)

  tut_rmd <- tempfile(fileext = ".Rmd")
  on.exit(unlink(tut_rmd))

  writeLines(ex, tut_rmd)
  tut_html <- rmarkdown::render(tut_rmd, quiet = TRUE)

  # overwrite exit handler to remove all tutorial files
  on.exit({
    rmarkdown::shiny_prerendered_clean(tut_rmd)
    unlink(tut_html)
    unlink(tut_rmd)
  }, add = FALSE)

  paste(readLines(tut_html), collapse = "\n")
}

default_solution <- "<code># DEFAULT SOLUTION 4631b0</code>"
hidden_solution <- "<code># HIDDEN SOLUTION 48da3c</code>"
shown_solution <- "<code># SHOWN SOLUTION 781cbb</code>"
ex_opt_solution <- "<code># EXERCISE OPT SOLUTION 15c861</code>"

test_that("Solutions are revealed or hidden with tutorial_options()", {
  skip_if_not(rmarkdown::pandoc_available())

  ex_show <- render_tutorial_with_reveal_solution("tutorial_options(exercise.reveal_solution = TRUE)")
  expect_match(ex_show, default_solution, fixed = TRUE)
  expect_failure(expect_match(ex_show, hidden_solution, fixed = TRUE))
  expect_match(ex_show, shown_solution, fixed = TRUE)
  expect_match(ex_show, ex_opt_solution, fixed = TRUE)

  ex_hide <- render_tutorial_with_reveal_solution("tutorial_options(exercise.reveal_solution = FALSE)")
  expect_failure(expect_match(ex_hide, default_solution, fixed = TRUE))
  expect_failure(expect_match(ex_hide, hidden_solution, fixed = TRUE))
  expect_match(ex_hide, shown_solution, fixed = TRUE)
  expect_match(ex_hide, ex_opt_solution, fixed = TRUE)
})

test_that("Solutions are revealed or hidden with global option", {
  skip_if_not(rmarkdown::pandoc_available())

  ex_show <- render_tutorial_with_reveal_solution("options(tutorial.exercise.reveal_solution = TRUE)")
  expect_match(ex_show, default_solution, fixed = TRUE)
  expect_failure(expect_match(ex_show, hidden_solution, fixed = TRUE))
  expect_match(ex_show, shown_solution, fixed = TRUE)
  expect_match(ex_show, ex_opt_solution, fixed = TRUE)

  ex_hide <- render_tutorial_with_reveal_solution("options(tutorial.exercise.reveal_solution = FALSE)")
  expect_failure(expect_match(ex_hide, default_solution, fixed = TRUE))
  expect_failure(expect_match(ex_hide, hidden_solution, fixed = TRUE))
  expect_match(ex_hide, shown_solution, fixed = TRUE)
  expect_match(ex_hide, ex_opt_solution, fixed = TRUE)
})
