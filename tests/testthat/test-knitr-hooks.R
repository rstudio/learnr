
context("knitr_hooks")

test_that("new_source_knit_hook works", {
  wsc_calls <- NULL
  mockWSC <- function(code, overwrite = FALSE) {
    wsc_calls <<- c(wsc_calls, list(code = code, overwrite = overwrite))
  }
  hook <- new_source_knit_hook(mockWSC)

  # If no original hook, and non-matching name, no-op
  knitr_hook_cache$source <- NULL
  hook(1, list(label="blah"))
  expect_equal(length(wsc_calls), 0)

  # If the block doesn't match our checks, just a pass-through to the original call
  origSourceCall <- NULL
  knitr_hook_cache$source <- function(...){ origSourceCall <<- list(...); 123 }
  res <- hook(1, list(label="blah"))
  expect_equal(length(wsc_calls), 0)
  expect_equal(origSourceCall, list(1, list(label="blah")))
  expect_equal(res, 123) # result should be whatever the original was

  # If it's a `setup` block, we stash it w/o overwrite
  res <- hook(1, list(label="setup", code=c("code", "here")))
  expect_equal(wsc_calls, list(code = c("code", "here"), overwrite = FALSE))
  expect_equal(res, 123) # result should be whatever the original source fun returned

  # If it's an `setup-global-exercise` block, we stash it w/ overwrite
  wsc_calls <- NULL
  res <- hook(1, list(label="setup-global-exercise", code=c("code", "here")))
  expect_equal(wsc_calls, list(code = c("code", "here"), overwrite = TRUE))
  expect_equal(res, 123) # result should be whatever the original source fun returned
})