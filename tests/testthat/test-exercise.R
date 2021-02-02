
# Test Exercise Mocking ---------------------------------------------------

test_that("exercise mocks: mock_prep_setup()", {
  chunks <- list(
    mock_chunk("setup-1", "x <- 1"),
    mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1"),
    mock_chunk("setup-3", "z <- 3", exercise.setup = "setup-2")
  )
  expect_equal(mock_prep_setup(chunks, "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks, "setup-2"), "x <- 1\ny <- 2")
  expect_equal(mock_prep_setup(chunks, "setup-1"), "x <- 1")

  # random order
  expect_equal(mock_prep_setup(chunks[3:1], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(1, 3, 2)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(2, 3, 1)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(2, 1, 3)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")

  # checks that setup chunk is in chunks
  expect_error(mock_prep_setup(chunks, "setup-Z"), "setup-Z")

  # cycles
  chunks[[1]]$opts$exercise.setup = "setup-3"
  expect_error(mock_prep_setup(chunks, "setup-3"), "-> setup-3$")

  # duplicate labels
  expect_error(mock_prep_setup(chunks[c(1, 1)], "setup-1"), "Duplicated")
})


# render_exercise() -------------------------------------------------------

test_that("render_exercise() returns exercise result with invisible value", {
  exercise <- mock_exercise(
    user_code = "z <- 3",
    chunks = list(
      mock_chunk("setup-1", "x <- 1"),
      mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1")
    ),
    setup_label = "setup-2"
  )

  base_envir <- new.env()
  exercise_result <- withr::with_tempdir(render_exercise(exercise, base_envir))
  expect_equal(exercise_result$last_value, 3)
  expect_match(as.character(exercise_result$html_output), "visible value")
  expect_equal(ls(exercise_result$envir_prep), c("x", "y"))
  expect_equal(ls(exercise_result$envir_result), c("x", "y", "z"))
  expect_equal(get("x", exercise_result$envir_prep), 1)
  expect_equal(get("x", exercise_result$envir_result), 1)
  expect_equal(get("y", exercise_result$envir_prep), 2)
  expect_equal(get("y", exercise_result$envir_result), 2)
  expect_error(get("z", exercise_result$envir_prep), "'z' not found")
  expect_equal(get("z", exercise_result$envir_result), 3)
})

test_that("render_exercise() returns exercise result with visible value and global setup chunk", {
  exercise <- mock_exercise(
    user_code = c("z <- 3", "z"),
    chunks = list(
      mock_chunk("setup-1", "x <- 1"),
      mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1")
    ),
    setup_label = "setup-2",
    global_setup = "w <- 0"
  )

  base_envir <- new.env()
  # Global setup is inherited from global env in evaluate_exercise()
  eval(parse(text = exercise$global_setup), envir = base_envir)

  exercise_result <- withr::with_tempdir(render_exercise(exercise, base_envir))
  expect_equal(exercise_result$last_value, 3)
  expect_equal(ls(exercise_result$envir_prep), c("w", "x", "y"))
  expect_equal(ls(exercise_result$envir_result), c("w", "x", "y", "z"))
  expect_equal(get("w", exercise_result$envir_prep), 0)
  expect_equal(get("w", exercise_result$envir_result), 0)
  expect_equal(get("x", exercise_result$envir_prep), 1)
  expect_equal(get("x", exercise_result$envir_result), 1)
  expect_equal(get("y", exercise_result$envir_prep), 2)
  expect_equal(get("y", exercise_result$envir_result), 2)
  expect_error(get("z", exercise_result$envir_prep), "'z' not found")
  expect_equal(get("z", exercise_result$envir_result), 3)
})

test_that("render_exercise() envir_prep and envir_result are distinct", {
  # user overwrites `x`
  exercise <- mock_exercise(
    user_code = c("x <- 2"),
    chunks = list(
      mock_chunk("setup-1", "x <- 1")
    ),
    setup_label = "setup-1"
  )

  exercise_result <- withr::with_tempdir(render_exercise(exercise, new.env()))

  expect_equal(exercise_result$last_value, 2)
  expect_match(as.character(exercise_result$html_output), "visible value")
  expect_equal(ls(exercise_result$envir_prep), "x")
  expect_equal(ls(exercise_result$envir_result), "x")
  expect_equal(get("x", exercise_result$envir_prep), 1)
  expect_equal(get("x", exercise_result$envir_result), 2)
})

test_that("render_exercise() returns identical envir_prep and envir_result if an error occurs in setup", {
  exercise <- mock_exercise(
    user_code = c("x <- 2"),
    chunks = list(
      mock_chunk("setup-1", c("x <- 1", "stop('boom')"))
    ),
    setup_label = "setup-1",
    error_check = "unevaluated, triggers error_check in render_exercise()"
  )

  exercise_result <- withr::with_tempdir(render_exercise(exercise, new.env()))

  # the error during render causes a checker evaluation, so we can recover
  # the environments from the checker_args returned by the debug checker
  exercise_result <- exercise_result$feedback$checker_args

  expect_s3_class(exercise_result$last_value, "simpleError")
  expect_equal(conditionMessage(exercise_result$last_value), "boom")

  expect_identical(exercise_result$envir_prep, exercise_result$envir_result)
})

test_that("render_exercise() returns envir_result up to error", {
  exercise <- mock_exercise(
    user_code = c("y <- 2", "stop('boom')", "z <- 3"),
    chunks = list(
      mock_chunk("setup-1", "x <- 1")
    ),
    setup_label = "setup-1",
    error_check = "unevaluated, triggers error_check in render_exercise()"
  )

  exercise_result <- withr::with_tempdir(render_exercise(exercise, new.env()))

  # the error during render causes a checker evaluation, so we can recover
  # the environments from the checker_args returned by the debug checker
  exercise_result <- exercise_result$feedback$checker_args

  expect_s3_class(exercise_result$last_value, "simpleError")
  expect_equal(conditionMessage(exercise_result$last_value), "boom")

  expect_false(identical(exercise_result$envir_prep, exercise_result$envir_result))
  expect_setequal(ls(exercise_result$envir_prep), "x")
  expect_setequal(ls(exercise_result$envir_result), c("x", "y"))
  expect_identical(get("y", exercise_result$envir_result), 2)
})

test_that("render_exercise() with errors and no checker returns exercise result error", {
  exercise <- mock_exercise(
    user_code = "stop('user')",
    chunks = list(mock_chunk("setup-1", "stop('setup')")),
    setup_label = "setup-1"
  )

  exercise_result <- withr::with_tempdir(render_exercise(exercise, new.env()))
  expect_s3_class(exercise_result, "learnr_exercise_result")
  expect_identical(exercise_result$error_message, "setup")
  expect_null(exercise_result$feedback)

  exercise <- mock_exercise(user_code = "stop('user')")
  exercise_result <- withr::with_tempdir(render_exercise(exercise, new.env()))
  expect_s3_class(exercise_result, "learnr_exercise_result")
  expect_identical(exercise_result$error_message, "user")
  expect_null(exercise_result$feedback)
})

# evaluate_exercise() -----------------------------------------------------

test_that("serialized exercises produce equivalent evaluate_exercise() results", {
  exercise <- mock_exercise(
    user_code = c("z <- 3", "z"),
    chunks = list(
      mock_chunk("setup-1", "x <- 1"),
      mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1")
    ),
    setup_label = "setup-2",
    global_setup = "w <- 0",
    check = I("identical(eval(parse(text = 'w + x + y + z'), envir_result), 6)")
  )

  # From internal_external_evaluator() in R/evaluators.R
  exercise_serialized <- jsonlite::toJSON(exercise, auto_unbox = TRUE, null = "null")
  # use parse_json() for safest parsing of serialized JSON (simplifyVector = FALSE)
  exercise_unserialized <- jsonlite::parse_json(exercise_serialized)

  # AsIs attribute doesn't survive serialization, but it's only used for testing
  exercise_unserialized$check <- I(exercise_unserialized$check)

  ex_eval_local <- evaluate_exercise(exercise, new.env(), TRUE)
  ex_eval_rmote <- evaluate_exercise(exercise_unserialized, new.env(), TRUE)

  env_vals <- function(env) {
    vars <- sort(ls(env))
    names(vars) <- vars
    lapply(vars, function(v) get(v, env))
  }

  expect_identical(
    ex_eval_local$feedback$checker_result,
    ex_eval_rmote$feedback$checker_result
  )
  expect_identical(
    ex_eval_local$feedback$checker_args$last_value,
    ex_eval_rmote$feedback$checker_args$last_value
  )
  expect_identical(
    env_vals(ex_eval_local$feedback$checker_args$envir_prep),
    env_vals(ex_eval_rmote$feedback$checker_args$envir_prep)
  )
  expect_identical(
    env_vals(ex_eval_local$feedback$checker_args$envir_result),
    env_vals(ex_eval_rmote$feedback$checker_args$envir_result)
  )
})
