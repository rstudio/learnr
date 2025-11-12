test_that("R auto complete finds runif vars", {
  expect_equal(auto_complete_r("this_variable_will_not_be_found"), list())
  expect_equal(
    auto_complete_r("runif"),
    list(
      list("runif", TRUE)
    )
  )
  expect_equal(
    auto_complete_r("runif("),
    list(
      list("n = ", FALSE),
      list("min = ", FALSE),
      list("max = ", FALSE)
    )
  )
})

test_that("R auto completions are not added when the line is a comment or quotes", {
  runif_fn <- list(list("runif", TRUE))

  # Establish expected autocomplete results
  expect_equal(auto_complete_r("1 + 1\nrunif"), runif_fn)

  # Completions should not be found when in a quote (even when started from a prior line)
  expect_equal(auto_complete_r("1 + 1\n'runif"), list())
  expect_equal(auto_complete_r("'1 + 1\nrunif"), list())
  expect_equal(auto_complete_r("\" ' #  # runif"), list())
  expect_equal(auto_complete_r("\" '   # runif"), list())

  # Comments on a prior line do not affect the auto completion
  expect_equal(auto_complete_r("# 1 + 1\nrunif"), runif_fn)

  # comments on a the last line do affect the auto completion
  expect_equal(auto_complete_r("1 + 1 \n# runif"), list())
  expect_equal(auto_complete_r("1 + 1 \nrunif #runif"), list())
  expect_equal(auto_complete_r("1 + 1 \n     \t   # runif"), list())
})

test_that("Local env overrides global env", {
  # Create a test env that contains another env nested within a label
  test_env <- new.env()
  test_env$test_runif <- runif
  label_env <- new.env()
  label_env$custom_runif <- function(a = 1, b = 2) {
    a + b + c
  }
  label_env$runif <- function(a = 1, b = 2) {
    a + b + c
  }
  test_env$my_label <- label_env

  # Find functions defined within the test env
  expect_equal(auto_complete_r("test_runif", NULL, NULL), list())
  expect_equal(
    auto_complete_r("test_runif", NULL, test_env),
    list(
      list("test_runif", TRUE)
    )
  )

  # Find custom runif function in a label's env
  expect_equal(auto_complete_r("custom_runif", NULL, NULL), list())
  expect_equal(
    auto_complete_r("custom_runif", "my_label", test_env),
    list(
      list("custom_runif", TRUE)
    )
  )
  expect_equal(auto_complete_r("custom_runif", "other_label", test_env), list())

  # # Auto complete currently (and previously) returned both the global and local runif parameters
  # # TODO-future; Only return the results from the local env
  # # Establish runif function is regularly found
  # expect_equal(auto_complete_r("runif(", NULL, NULL), list(
  #   list("n = ", FALSE),
  #   list("min = ", FALSE),
  #   list("max = ", FALSE)
  # ))
  # # Find custom runif function in a label's env
  # expect_equal(auto_complete_r("runif(", "my_label", test_env), list(
  #   list("a = ", FALSE),
  #   list("b = ", FALSE)
  # ))
})

test_that("detect_comments()", {
  expect_false(detect_comment(""))
  expect_false(detect_comment("runif()"))
  expect_true(detect_comment("#runif()"))
  expect_true(detect_comment("runif() # random uniform"))
  expect_true(detect_comment("#runif() # random uniform"))
  expect_false(detect_comment("paste('# not a comment')"))
  expect_false(detect_comment("paste('# \'still\' # not a comment')"))
  expect_false(detect_comment("paste('# \"still\" # not a comment')"))
  expect_true(detect_comment(
    "paste('# \"still\" # not a comment') # is a comment"
  ))

  expect_false(detect_comment('" \' # "'))
  expect_true(detect_comment('" \' # " # runif'))
  expect_false(detect_comment('" \' # "'))
  expect_true(detect_comment('" \'  " # runif'))
  expect_false(detect_comment('" \' # "'))
  expect_true(detect_comment("' \" # ' # runif"))
  expect_false(detect_comment('" \' # "'))
  expect_true(detect_comment("' \"  ' # runif"))
})
