test_that("R auto complete finds runif vars", {

  expect_equal(auto_complete_r("method not found", NULL, NULL), list())
  expect_equal(auto_complete_r("runif", NULL, NULL), list(
    list("runif", TRUE)
  ))
  expect_equal(auto_complete_r("runif(", NULL, NULL), list(
    list("n = ", FALSE),
    list("min = ", FALSE),
    list("max = ", FALSE)
  ))
})

test_that("R auto completions are not added when the line is a comment or quotes", {
  runif_fn <- list(list("runif", TRUE))

  # Establish expected autocomplete results
  expect_equal(auto_complete_r("1 + 1\nrunif", NULL, NULL), runif_fn)

  # Completions should not be found when in a quote (even when started from a prior line)
  expect_equal(auto_complete_r("1 + 1\n'runif", NULL, NULL), list())
  expect_equal(auto_complete_r("'1 + 1\nrunif", NULL, NULL), list())

  # Quotes on a prior line do not affect the auto completion
  expect_equal(auto_complete_r("# 1 + 1\nrunif", NULL, NULL), runif_fn)

  # Quotes on a the last line do affect the auto completion
  expect_equal(auto_complete_r("1 + 1 \n# runif", NULL, NULL), list())
  expect_equal(auto_complete_r("1 + 1 \n     \t   # runif", NULL, NULL), list())
})
