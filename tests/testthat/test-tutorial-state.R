test_that("store works", {
  # First write works
  expect_equal(store_tutorial_cache("myName", c("code", "here"), FALSE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Second write without overwrite is a no-op
  expect_equal(
    store_tutorial_cache("myName", c("updated", "code"), FALSE),
    FALSE
  )
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Overwrite returns true
  expect_equal(store_tutorial_cache("myName", c("updated", "code"), TRUE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("updated", "code"))

  # clear clears
  expect_warning(clear_exercise_cache_env(), "deprecated")
  expect_equal(length(get_tutorial_cache("exercise")), 0)
})


test_that("get_tutorial_info() returns structured tutorial cache", {
  skip_if_not_pandoc("1.14")

  info <- get_tutorial_info(test_path("tutorials", "basic.Rmd"))
  withr::defer(clear_tutorial_cache())

  # prepare_tutorial_cache() returns get_tutorial_info()
  expect_equal(info$tutorial_id, "test-basic")
  expect_equal(info$tutorial_version, "9.9.9")
  expect_s3_class(info$items, "data.frame")
  expect_named(info$items, c("order", "label", "type", "data"))

  all <- get_tutorial_cache()
  for (i in seq_along(info$items$data)) {
    item <- info$items$data[[i]]
    label <- info$items$label[[i]]

    if (inherits(item, "tutorial_exercise")) {
      # these items are added by app or by `get_tutorial_info()`
      item[["code"]] <- NULL
    }
    expect_equal(item, all[[label]])
  }

  # tutorial cache lists items in order of appearance
  exercises <- c("two-plus-two", "add-function", "print-limit")
  questions <- c("quiz-1", "quiz-2")
  expect_equal(names(all), c(exercises, questions))

  expect_equal(all[exercises], get_exercise_cache())
  expect_equal(all$`two-plus-two`, get_exercise_cache("two-plus-two"))
  expect_true(all(vapply(
    all[exercises],
    inherits,
    logical(1),
    "tutorial_exercise"
  )))

  expect_equal(all[questions], get_question_cache())
  expect_equal(all$`quiz-2`, get_question_cache("quiz-2"))
  expect_true(all(vapply(
    all[questions],
    inherits,
    logical(1),
    "tutorial_question"
  )))

  # exercises have the same `global_setup`
  expect_equal(all$`two-plus-two`$global_setup, all$`add-function`$global_setup)
  expect_equal(all$`two-plus-two`$global_setup, all$`print-limit`$global_setup)
  expect_equal(all$`add-function`$options$exercise.lines, 5)
})


test_that("setup-global-exercise chunk is used for global_setup", {
  skip_if_not_pandoc("1.14")

  prepare_tutorial_cache_from_source(test_path(
    "setup-chunks",
    "exercise-global-setup.Rmd"
  ))
  withr::defer(clear_tutorial_cache())

  all <- get_tutorial_cache()

  expect_equal(as.character(all$data1$global_setup), "global <- 0")
  # check that the correct chunk was used for the `global_setup`
  # NOTE: this may change if the knitr hooks are refactored
  expect_equal(
    attr(all$data1$global_setup, "chunk_opts")$label,
    "setup-global-exercise"
  )

  ex <- mock_exercise(
    user_code = "global",
    label = "data1",
    check = I("global")
  )
  ex$chunks <- all$data1$chunks
  ex$global_setup <- all$data1$global_setup
  ex$setup <- all$data1$setup

  # global setup chunk is not evaluated unless explicitly requested
  res <- evaluate_exercise(ex, evaluate_global_setup = FALSE, envir = new.env())
  expect_equal(res$error_message, "object 'global' not found")

  res <- evaluate_exercise(ex, evaluate_global_setup = TRUE, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, 0)
})
