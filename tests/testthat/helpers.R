
# https://github.com/rstudio/rmarkdown/blob/2faee0040a39008a47bdf1ba840bf402cba15a65/tests/testthat/helpers.R

skip_if_not_pandoc <- function(ver = NULL) {
  if (!rmarkdown::pandoc_available(ver)) {
    msg <- if (is.null(ver)) {
      "Pandoc is not available"
    } else {
      sprintf("Version of Pandoc is lower than %s.", ver)
    }
    skip(msg)
  }
}

skip_if_pandoc <- function(ver = NULL) {
  if (rmarkdown::pandoc_available(ver)) {
    msg <- if (is.null(ver)) {
      "Pandoc is available"
    } else {
      sprintf("Version of Pandoc is greater than %s.", ver)
    }
    skip(msg)
  }
}

skip_on_ci_if_not_pr <- function() {
  # Don't skip locally
  if (!nzchar(Sys.getenv("CI", ""))) return()
  # If on CI, don't skip if envvar set by workflow is present
  if (nzchar(Sys.getenv("CI_IN_PR", ""))) return()
  # If on CI and not in a PR branch workflow... skip these tests
  skip("Skipping on CI, tests run in PR checks only")
}

expect_marked_as <- function(object, correct, messages = NULL) {
  if (is.null(messages)) {
    expect_equal(object, mark_as(correct))
    return()
  }

  if (length(messages) > 1) {
    messages_orig <- messages
    messages <- quiz_text(messages_orig[[1]])
    for (i in seq_along(messages_orig)[-1]) {
      messages <- htmltools::tagList(messages, messages_orig[[i]])
    }
  }

  expect_equal(object, mark_as(correct, messages))
}
