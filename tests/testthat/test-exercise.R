
# exercise_code_chunks() --------------------------------------------------

test_that("exercise_code_chunks_prep() returns setup/user chunks", {
  exercise <- mock_exercise(
    user_code = "USER",
    chunks = list(
      mock_chunk("setup-a", "SETUP A"),
      mock_chunk("setup-b", "SETUP B", exercise.setup = "setup-a")
    )
  )

  chunks_prep <- exercise_code_chunks_prep(exercise)
  expect_length(chunks_prep, 2)
  expect_match(chunks_prep[1], "SETUP A")
  expect_match(chunks_prep[2], "SETUP B")

  chunks_user <- exercise_code_chunks_user(exercise)
  expect_length(chunks_user, 1)
  expect_match(chunks_user, "USER")
})

test_that("exercise_code_chunks_prep() returns character(0) if no chunks", {
  expect_length(exercise_code_chunks_prep(mock_exercise()), 0)
  expect_identical(exercise_code_chunks_prep(mock_exercise()), character(0))
})

# render_exercise() -------------------------------------------------------

test_that("render_exercise() returns exercise result with invisible value", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = "z <- 3",
    chunks = list(
      mock_chunk("setup-1", "x <- 1"),
      mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1")
    ),
    setup_label = "setup-2",
    exercise.warn_invisible = TRUE
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
  skip_if_not_pandoc("1.14")

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
  skip_if_not_pandoc("1.14")

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

test_that("render_exercise() returns envir_result up to error", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = c("y <- 2", "stop('boom')", "z <- 3"),
    chunks = list(
      mock_chunk("setup-1", "x <- 1")
    ),
    setup_label = "setup-1",
    error_check = "unevaluated, triggers error_check in render_exercise()"
  )

  exercise_result <- withr::with_tempdir(
    rlang::catch_cnd(
      render_exercise(exercise, new.env()), "learnr_render_exercise_error"
    )
  )

  expect_s3_class(exercise_result$last_value, "simpleError")
  expect_equal(conditionMessage(exercise_result$last_value), "boom")

  expect_false(
    identical(exercise_result$envir_prep, exercise_result$envir_result)
  )
  expect_setequal(ls(exercise_result$envir_prep), "x")
  expect_setequal(ls(exercise_result$envir_result), c("x", "y"))
  expect_identical(get("y", exercise_result$envir_result), 2)
})

test_that("evaluate_exercise() returns internal error if setup chunk throws an error", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = "stop('user')",
    chunks = list(mock_chunk("setup-1", "stop('setup')")),
    setup_label = "setup-1",
    exercise.error.check.code = NULL
  )
  expect_warning(
    exercise_result <- evaluate_exercise(exercise, new.env()),
    "rendering exercise setup"
  )
  expect_match(exercise_result$feedback$message, "setting up the exercise")
  expect_null(exercise_result$error_message)
})

test_that("evaluate_exercise() returns error in exercise result if no error checker", {
  exercise <- mock_exercise(
    user_code = "stop('user')",
    error_check = NULL,
    exercise.error.check.code = NULL
  )

  exercise_result <- evaluate_exercise(exercise, new.env())
  expect_equal(exercise_result$error_message, "user")
  expect_null(exercise_result$feedback)
})

test_that("evaluate_exercise() errors from setup chunks aren't checked by error checker", {
  exercise <- mock_exercise(
    user_code = "stop('user')",
    chunks = list(mock_chunk("setup-1", "stop('setup')")),
    setup_label = "setup-1",
    error_check = I("'error_check'"),
    exercise.error.check.code = I("'default_error_check'")
  )
  expect_warning(
    exercise_result <- evaluate_exercise(exercise, new.env()),
    "error occurred while rendering"
  )
  expect_match(exercise_result$feedback$message, "internal error occurred")
  # internal error condition is passed around in $feedback$error
  expect_s3_class(exercise_result$feedback$error, "simpleError")
  expect_match(conditionMessage(exercise_result$feedback$error), "setup")
})

test_that("evaluate_exercise() errors from user code are checked by error_checker", {
  exercise <- mock_exercise(
    user_code = "stop('user')",
    error_check = I("'error_check'"),
    exercise.error.check.code = I("'default_error_check'")
  )

  exercise_result <- evaluate_exercise(exercise, new.env())
  # check that error check function was called
  expect_equal(exercise_result$feedback$checker_result, "error_check")
  expect_equal(exercise_result$error_message, "user")
  expect_s3_class(exercise_result$feedback$checker_args$last_value, "simpleError")
  expect_equal(
    conditionMessage(exercise_result$feedback$checker_args$last_value),
    exercise_result$error_message
  )
})

test_that("evaluate_exercise() errors from user code are checked by default error checker as a fallback", {
  exercise <- mock_exercise(
    user_code = "stop('user')",
    check = I("stop('test failed')"),
    error_check = NULL,
    exercise.error.check.code = I("'default_error_check'")
  )

  exercise_result <- evaluate_exercise(exercise, new.env())
  # check that default error check function was called
  expect_equal(exercise_result$feedback$checker_result, "default_error_check")
  expect_equal(exercise_result$error_message, "user")
  expect_s3_class(exercise_result$feedback$checker_args$last_value, "simpleError")
  expect_equal(
    conditionMessage(exercise_result$feedback$checker_args$last_value),
    exercise_result$error_message
  )
})

test_that("evaluate_exercise() returns an internal error for global setup chunk evaluation errors", {
  ex <- mock_exercise(global_setup = "stop('global setup failure')")
  expect_warning(
    res <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE),
    "evaluating the global setup"
  )
  expect_equal(conditionMessage(res$feedback$error), "global setup failure")
  expect_match(res$feedback$message, "setting up the tutorial")
  expect_s3_class(res$feedback$error, "simpleError")
})

test_that("evaluate_exercise() returns an internal error when `render_exercise()` fails", {
  local_edition(2)
  with_mock(
    "learnr:::render_exercise" = function(...) stop("render error"),
    expect_warning(
      res <- evaluate_exercise(mock_exercise(), new.env())
    )
  )

  expect_match(res$feedback$message, "evaluating your exercise")
  expect_s3_class(res$feedback$error, "simpleError")
  expect_equal(conditionMessage(res$feedback$error), "render error")
})

test_that("render_exercise() cleans up exercise_prep files", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = "dir()",
    chunks = list(mock_chunk("ex-setup", "n <- 5"))
  )

  files <- withr::with_tempdir({
    res <- render_exercise(exercise, new.env())
    list(
      during = res$last_value,
      after = dir()
    )
  })

  # The exercise prep .Rmd is gone before the exercise runs
  expect_false(all(grepl("exercise_prep", files$during)))
  expect_false(all(grepl("exercise_prep", files$after)))
  # Only exercise.Rmd is in the working directory (by default)
  expect_equal(files$during, "exercise.Rmd")
})

test_that("render_exercise() cleans up exercise_prep files even when setup fails", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = c("writeLines('nope', 'nope.txt')", "dir()"),
    # setup chunk throws an error
    chunks = list(mock_chunk("ex-setup", c("rlang::abort('setup-error', dir = dir())"))),
    # get file listing after error in setup chunk happens
    error_check = I("dir()")
  )

  files <- expect_warning(
    expect_message(
      withr::with_tempdir({
        before <- dir()
        env <- new.env()
        res <- render_exercise(exercise, env)
        list(
          before = before,
          during = res$feedback$error$dir,
          after  = dir()
        )
      }),
      "exercise_prep.Rmd"
    )
  )

  # start with nothing
  expect_identical(files$before, character(0))
  # prep file is present while evaluating prep
  expect_identical(files$during, "exercise_prep.Rmd")
  # nothing in directory after render_exercise() because user code didn't evaluate
  expect_identical(files$after, character(0))
})

test_that("render_exercise() warns if exercise setup overwrites exercise.Rmd", {
  skip_if_not_pandoc("1.14")

  exercise <- mock_exercise(
    user_code = "readLines('exercise.Rmd')",
    chunks = list(mock_chunk("ex-setup", "writeLines('nope', 'exercise.Rmd')"))
  )

  res <- expect_warning(
    withr::with_tempdir({
      before <- dir()
      res <- render_exercise(exercise, new.env())
      list(
        before = before,
        during = res$last_value,
        after = readLines('exercise.Rmd')
      )
    }),
    "exercise.Rmd"
  )

  expect_equal(res$before, character(0))
  expect_false(identical('nope', res$during))
  expect_equal(res$during, res$after)
})

test_that("render_exercise() exercise chunk options are used when rendering user code", {
  ex <- mock_exercise(
    user_code = "knitr::opts_current$get('a_custom_user_chunk_opt')",
    a_custom_user_chunk_opt = "PASS"
  )

  res <- withr::with_tempdir(render_exercise(ex, new.env()))

  expect_equal(ex$options$a_custom_user_chunk_opt, "PASS")
  expect_equal(res$last_value, "PASS")
})

test_that("render_exercise() user code exercise.Rmd snapshot", {
  local_edition(3)

  ex <- mock_exercise(
    user_code = 'USER_CODE <- "PASS"',
    solution_code = "SOLUTION_CODE",
    chunks = list(
      mock_chunk("ex-setup", "SETUP_CODE")
    )
  )
  expect_snapshot(writeLines(exercise_code_chunks_user_rmd(ex)))

  ex_sql <- mock_exercise(
    user_code = 'SELECT * FROM USER',
    solution_code = "SELECT * FROM SOLUTION",
    engine = "sql"
  )
  expect_snapshot(writeLines(exercise_code_chunks_user_rmd(ex_sql)))
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
  exercise_serialized <- jsonlite::toJSON(exercise, auto_unbox = TRUE, null = "null", force = TRUE)
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

test_that("standardize_exercise_result() ensures top-level code is length-1 string", {
  ex <- standardize_exercise_code(
    list(
      code = c("a", "b"),
      check = character(),
      code_check = c("  ", "  ", "\t\t\t"),
      global_setup = c(
        "",
        "def return_one():",
        "\treturn 1",
        ""
      )
    )
  )

  expect_equal(ex$code, "a\nb")
  expect_equal(ex$check, "")
  expect_equal(ex$code_check, "")
  expect_equal(ex$global_setup, "def return_one():\n\treturn 1")
})

test_that("evaluate_exercise() handles default vs. explicit error check code", {
  ex <- mock_exercise(
    "stop('boom!')",
    check = I("stop('test failed')"),
    error_check = NULL,
    exercise.error.check.code = I("'default_error_check_code'")
  )

  res <- evaluate_exercise(ex, new.env())
  expect_equal(res$feedback$checker_result, "default_error_check_code")
  expect_s3_class(res$feedback$checker_args$last_value, "simpleError")
  expect_match(conditionMessage(res$feedback$checker_args$last_value), "boom")
})

# exercise_result() -------------------------------------------------------

test_that("exercise_result() doesn't concatenate feedback and code output", {
  feedback <- list(correct = TRUE, message = "<p>FEEDBACK</p>")
  result <- exercise_result(
    feedback = feedback,
    html_output = "<pre><code>## output</code></pre>"
  )

  expect_s3_class(result, "learnr_exercise_result")
  expect_equal(result$html_output, "<pre><code>## output</code></pre>")
  expect_equal(
    result$feedback$html,
    feedback_as_html(feedback)
  )
  expect_match(as.character(result$feedback$html), "FEEDBACK", fixed = TRUE)
  expect_false(grepl("FEEDBACK", result$html_output))
})

test_that("exercise_result() throws an error for invalid feedback", {
  expect_error(exercise_result(feedback = list(bad = TRUE)))
  expect_error(exercise_result(feedback = list(correct = FALSE)))
  expect_error(exercise_result(feedback = list(correct = "wrong")))
})

test_that("exercise_result_as_html() creates html for learnr", {
  expect_null(exercise_result_as_html("nope"))
  expect_null(exercise_result_as_html(list()))

  code_output <- htmltools::HTML("<pre><code>## output</code></pre>")
  feedback <- list(message = htmltools::HTML("<p>FEEDBACK</p>"), correct = TRUE)

  result_no_feedback <- exercise_result(html_output = code_output)
  result <- exercise_result(feedback = feedback, html_output = code_output)

  # exercise_result() doesn't include feedback in the html_output
  expect_equal(result_no_feedback$html_output, result$html_output)

  # code output is found in the output in both cases
  expect_match(
    as.character(exercise_result_as_html(result)),
    as.character(exercise_result_as_html(result_no_feedback)),
    fixed = TRUE
  )

  # feedback is added to the html output by exercise_result_as_html()
  expect_true(
    grepl(
      "FEEDBACK",
      as.character(exercise_result_as_html(result)),
      fixed = TRUE
    )
  )

  # feedback is appended
  feedback_html <- as.character(feedback_as_html(feedback))
  result_html <- as.character(exercise_result_as_html(result))

  str_locate <- function(x, pattern) {
    r <- regexec(as.character(pattern), as.character(x))
    r[[1]][[1]]
  }

  expect_equal(
    str_locate(result_html, feedback_html),
    nchar(result_html) - nchar(feedback_html) + 1
  )

  # feedback is prepended
  result$feedback$location <- "prepend"
  result_html <- as.character(exercise_result_as_html(result))
  expect_equal(str_locate(result_html, feedback_html), 1)

  # feedback replaces output
  result$feedback$location <- "replace"
  result_html <- as.character(exercise_result_as_html(result))
  expect_equal(result_html, feedback_html)

  # bad feedback location results in error
  result$feedback$location <- "nope"
  expect_error(exercise_result_as_html(result))
})

# filter_dependencies() ---------------------------------------------------

test_that("filter_dependencies() excludes non-list knit_meta objects", {
  skip_if_not_pandoc("1.14")

  ex <- mock_exercise(
    user_code =
      "htmltools::tagList(
        htmltools::tags$head(htmltools::tags$style(\".leaflet-container {backround:#FFF}\")),
        idb_html_dependency()
      )"
  )

  ex_res <- expect_silent(withr::with_tempdir(render_exercise(ex, new.env())))

  ex_res_html_deps <- htmltools::htmlDependencies(ex_res$html_output)
  # The head(style) dependency is dropped because it's not from a package
  expect_equal(length(ex_res_html_deps), 1L)
  # But we keep the dependency that came from a pkg
  expect_equal(
    ex_res_html_deps[[1]],
    idb_html_dependency()
  )
})

test_that("exercise versions upgrade correctly", {
  expect_error(upgrade_exercise(mock_exercise(version = NULL)))
  expect_error(upgrade_exercise(mock_exercise(version = 1:2)))
  expect_error(upgrade_exercise(mock_exercise(version = list(a = 1, b = 2))))
  expect_error(upgrade_exercise(mock_exercise(version = "0")))
  expect_error(upgrade_exercise(mock_exercise(version = "foo")))

  ex_1 <- mock_exercise(version = "1")
  expect_null(ex_1$tutorial)

  ex_1_upgraded <- upgrade_exercise(ex_1)
  expect_match(ex_1_upgraded$tutorial$tutorial_id, "UPGRADE")
  expect_match(ex_1_upgraded$tutorial$tutorial_version, "-1")
  expect_match(ex_1_upgraded$tutorial$user_id, "UPGRADE")
  expect_equal(paste(ex_1_upgraded$version), "3")

  ex_2 <- mock_exercise(version = "2")
  expect_type(ex_2$tutorial, "list")
  ex_2$tutorial$language <- "en"
  expect_identical(ex_2$tutorial, upgrade_exercise(ex_2)$tutorial)

  i18n_set_language_option("foo")
  ex_2 <- mock_exercise(version = "2")
  expect_type(ex_2$tutorial, "list")
  ex_2$tutorial$language <- "foo"
  expect_identical(ex_2$tutorial, upgrade_exercise(ex_2)$tutorial)
  knitr::opts_knit$set("tutorial.language" = NULL)

  ex_3 <- mock_exercise(version = "3")
  expect_type(ex_3$tutorial, "list")
  expect_identical(ex_3$tutorial, upgrade_exercise(ex_3)$tutorial)

  # future versions
  ex_99 <- mock_exercise(version = 99)
  expect_equal(
    expect_warning(upgrade_exercise(ex_99)),
    ex_99
  )

  # broken but okay future version
  ex_99_broken <- ex_99
  ex_99_broken$global_setup <- NULL
  expect_equal(
    expect_warning(upgrade_exercise(ex_99_broken)),
    ex_99_broken
  )

  # broken but not okay
  expect_error(upgrade_exercise(ex_99_broken, require_items = "global_setup"))

  # broken in other non-optional ways
  # (this version of learnr makes a strong assumption that "label" is part of exercise)
  ex_99_broken$label <- NULL
  expect_error(upgrade_exercise(ex_99_broken))
})

# data files -----------------------------------------------------------------

test_that("data/ - files in data/ directory can be accessed", {
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("ORIGINAL", "data/test.txt")

  ex  <- mock_exercise(user_code = 'readLines("data/test.txt")', check = TRUE)
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, "ORIGINAL")
})

test_that("data/ - no issues if data directory does not exist", {
  withr::local_dir(withr::local_tempdir())

  ex  <- mock_exercise(user_code = '"SUCCESS"', check = TRUE)
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, "SUCCESS")
})

test_that("data/ - original files are modified by exercise code", {
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("ORIGINAL", "data/test.txt")

  ex <- mock_exercise(
    user_code = '
    writeLines("MODIFIED", "data/test.txt")
    readLines("data/test.txt")
    ',
    check = TRUE
  )
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, "MODIFIED")
  expect_equal(readLines("data/test.txt"),           "ORIGINAL")
})

test_that("data/ - specify alternate data directory with envvar", {
  withr::local_envvar(list("TUTORIAL_DATA_DIR" = "envvar"))
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("DEFAULT", "data/test.txt")
  dir.create("envvar")
  writeLines("ENVVAR", "envvar/test.txt")

  ex  <- mock_exercise(user_code = 'readLines("data/test.txt")', check = TRUE)
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, "ENVVAR")

  ex <- mock_exercise(
    user_code = '
      writeLines("MODIFIED", "data/test.txt")
      readLines("data/test.txt")
    ',
    check = TRUE
  )
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value, "MODIFIED")
  expect_equal(readLines("data/test.txt"),           "DEFAULT")
  expect_equal(readLines("envvar/test.txt"),         "ENVVAR")
})

test_that("data/ - errors if envvar directory does not exist", {
  withr::local_envvar(list("TUTORIAL_DATA_DIR" = "envvar"))
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("DEFAULT", "data/test.txt")

  ex <- mock_exercise(user_code = 'readLines("data/test.txt")')
  expect_error(
    evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE),
    class = "learnr_missing_source_data_dir"
  )
})

test_that("data/ - specify alternate data directory with `options()`", {
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("DEFAULT", "data/test.txt")
  dir.create("nested/structure/data", recursive = TRUE)
  writeLines("NESTED", "nested/structure/test.txt")

  ex  <- mock_exercise(user_code = 'readLines("data/test.txt")', check = TRUE)
  res <- evaluate_exercise(ex, envir = new.env())
  expect_equal(res$feedback$checker_args$last_value,   "DEFAULT")
  expect_equal(readLines("data/test.txt"),             "DEFAULT")
  expect_equal(readLines("nested/structure/test.txt"), "NESTED")

  ex <- mock_exercise(
    user_code    = 'readLines("data/test.txt")',
    global_setup = 'options(tutorial.data_dir = "nested/structure")',
    check        = TRUE
  )
  res <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE)
  expect_equal(res$feedback$checker_args$last_value, "NESTED")

  ex <- mock_exercise(
    user_code = '
      writeLines("MODIFIED", "data/test.txt")
      readLines("data/test.txt")
    ',
    global_setup = 'options(tutorial.data_dir = "nested/structure")',
    check        = TRUE
  )
  res <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE)
  expect_equal(res$feedback$checker_args$last_value,   "MODIFIED")
  expect_equal(readLines("data/test.txt"),             "DEFAULT")
  expect_equal(readLines("nested/structure/test.txt"), "NESTED")
})

test_that("data/ - errors if `options()` directory does not exist", {
  withr::local_dir(withr::local_tempdir())
  ex <- mock_exercise(
    user_code    = 'readLines("data/test.txt")',
    global_setup = 'options(tutorial.data_dir = "nested/structure")'
  )
  expect_error(
    evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE),
    class = "learnr_missing_source_data_dir"
  )
})

test_that("data/ - data directory option has precendence over envvar", {
  withr::local_envvar(list("TUTORIAL_DATA_DIR" = "envvar"))
  withr::local_dir(withr::local_tempdir())
  dir.create("data")
  writeLines("DEFAULT", "data/test.txt")
  dir.create("nested/structure/data", recursive = TRUE)
  writeLines("NESTED", "nested/structure/test.txt")
  dir.create("envvar")
  writeLines("ENVVAR", "envvar/test.txt")

  ex <- mock_exercise(
    user_code    = 'readLines("data/test.txt")',
    global_setup = 'options(tutorial.data_dir = "nested/structure")',
    check        = TRUE
  )
  res <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE)
  expect_equal(res$feedback$checker_args$last_value, "NESTED")
})

# global options are restored after running user code ---------------------

test_that("options() are protected from student modification", {
  withr::local_options(test = "WITHR")
  expect_match(getOption("test"), "WITHR", fixed = TRUE)

  ex <- mock_exercise(
    user_code = "options(test = 'USER')\ngetOption('test')"
  )
  output <- evaluate_exercise(ex, envir = new.env())
  expect_match(output$html_output, "USER", fixed = TRUE)
  expect_match(getOption("test"),  "WITHR", fixed = TRUE)
})

test_that("options() can be set in setup chunk", {
  withr::local_options(test = "WITHR")

  ex <- mock_exercise(
    user_code   = "getOption('test')",
    chunks      = list(mock_chunk("setup", "options(test = 'SETUP')")),
    setup_label = "setup"
  )
  output <- evaluate_exercise(
    ex, envir = new.env(), evaluate_global_setup = TRUE
  )
  expect_match(output$html_output, "SETUP", fixed = TRUE)
  expect_match(getOption("test"),  "WITHR", fixed = TRUE)

  ex <- mock_exercise(
    user_code    = "options(test = 'USER')\ngetOption('test')",
    chunks      = list(mock_chunk("setup", "options(test = 'SETUP')")),
    setup_label = "setup"
  )
  output <- evaluate_exercise(
    ex, envir = new.env(), evaluate_global_setup = TRUE
  )
  expect_match(output$html_output, "USER", fixed = TRUE)
  expect_match(getOption("test"),  "WITHR", fixed = TRUE)
})

test_that("options() can be set in global setup chunk", {
  withr::local_options(test = "WITHR")

  ex <- mock_exercise(
    user_code    = "getOption('test')",
    global_setup = "options(test = 'GLOBAL')"
  )
  output <- evaluate_exercise(
    ex, envir = new.env(), evaluate_global_setup = TRUE
  )
  expect_match(output$html_output, "GLOBAL", fixed = TRUE)
  expect_match(getOption("test"),  "WITHR",  fixed = TRUE)

  ex <- mock_exercise(
    user_code    = "options(test = 'USER')\ngetOption('test')",
    global_setup = "options(test = 'GLOBAL')"
  )
  output <- evaluate_exercise(
    ex, envir = new.env(), evaluate_global_setup = TRUE
  )
  expect_match(output$html_output, "USER",  fixed = TRUE)
  expect_match(getOption("test"),  "WITHR", fixed = TRUE)

  ex <- mock_exercise(
    user_code    = "getOption('test')",
    global_setup = "options(test = 'GLOBAL')",
    chunks       = list(mock_chunk("setup", "options(test = 'SETUP')")),
    setup_label  = "setup"
  )
  output <- evaluate_exercise(
    ex, envir = new.env(), evaluate_global_setup = TRUE
  )
  expect_match(output$html_output, "SETUP", fixed = TRUE)
  expect_match(getOption("test"),  "WITHR", fixed = TRUE)
})

test_that("envvars are protected from student modification", {
  withr::local_envvar(list(TEST = "WITHR"))
  expect_match(Sys.getenv("TEST"), "WITHR", fixed = TRUE)

  ex <- mock_exercise(
    user_code = "Sys.setenv(TEST = 'USER')\nSys.getenv('TEST')"
  )
  output <- evaluate_exercise(ex, envir = new.env())
  expect_match(output$html_output, "USER", fixed = TRUE)
  expect_match(Sys.getenv("TEST"),  "WITHR", fixed = TRUE)
})

test_that("options are protected from both user and author modification", {
  withr::local_options(list(TEST = "APP"))

  ex <- mock_exercise(
    user_code = "user <- getOption('TEST')\noptions(TEST = 'USER')",
    check = I(paste(
      'check <- getOption("TEST")',
      'options(TEST = "CHECK")',
      'list(user = envir_result$user, check = check)',
      sep = "\n"
    ))
  )

  res <- evaluate_exercise(ex, new.env())$feedback$checker_result
  res$after_eval <- getOption("TEST")

  # user code sees TEST = "APP" but overwrites it
  expect_equal(res$user, "APP")

  # it's reset after render_exercise() so check code sees "APP", also overwrites
  expect_equal(res$check, "APP")

  # evaluate_exercise() restores the TEST option after checking too
  expect_equal(res$after_eval, "APP")
})

test_that("env vars are protected from both user and author modification", {
  withr::local_envvar(list(TEST = "APP"))

  ex <- mock_exercise(
    user_code = "user <- Sys.getenv('TEST')\nSys.setenv(TEST = 'USER')",
    check = I(paste(
      'check <- Sys.getenv("TEST")',
      'Sys.setenv(TEST = "CHECK")',
      'list(user = envir_result$user, check = check)',
      sep = "\n"
    ))
  )

  res <- evaluate_exercise(ex, new.env())$feedback$checker_result
  res$after_eval <- Sys.getenv("TEST")

  # user code sees TEST = "APP" but overwrites it
  expect_equal(res$user, "APP")

  # it's reset after render_exercise() so check code sees "APP", also overwrites
  expect_equal(res$check, "APP")

  # evaluate_exercise() restores the TEST option after checking too
  expect_equal(res$after_eval, "APP")
})

# Blanks ------------------------------------------------------------------

test_that("evaluate_exercise() returns a message if code contains ___", {
  ex     <- mock_exercise(user_code = '____("test")')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:1")
  expect_match(result$feedback$message, "This exercise contains 1 blank.")
  expect_match(result$feedback$message, "Please replace <code>____</code> with valid code.")

  ex     <- mock_exercise(user_code = '____(____)')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:2")
  expect_match(result$feedback$message, "This exercise contains 2 blanks.")
  expect_match(result$feedback$message, "Please replace <code>____</code> with valid code.")

  ex     <- mock_exercise(user_code = '____("____")')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:2")
  expect_match(result$feedback$message, "This exercise contains 2 blanks.")
  expect_match(result$feedback$message, "Please replace <code>____</code> with valid code.")
})

test_that("setting a different blank for the blank checker", {
  ex     <- mock_exercise(user_code = '####("test")', exercise.blanks = "###")
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:1")
  expect_match(result$feedback$message, "This exercise contains 1 blank.")
  expect_match(result$feedback$message, "Please replace <code>###</code> with valid code.")

  ex     <- mock_exercise(user_code = '####(####)', exercise.blanks = "###")
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:2")
  expect_match(result$feedback$message, "This exercise contains 2 blanks.")
  expect_match(result$feedback$message, "Please replace <code>###</code> with valid code.")

  ex     <- mock_exercise(user_code = '####("####")', exercise.blanks = "###")
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:2")
  expect_match(result$feedback$message, "This exercise contains 2 blanks.")
  expect_match(result$feedback$message, "Please replace <code>###</code> with valid code.")
})

test_that("setting a different blank for the blank checker in global setup", {
  # global setup code, when evaluated, pollutes our global knitr options
  withr::defer(knitr::opts_chunk$set(exercise.blanks = NULL))

  ex <- mock_exercise(
    user_code    = '####("test")',
    global_setup = 'knitr::opts_chunk$set(exercise.blanks = "###")'
  )
  result <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE)
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:1")

  expect_match(result$feedback$message, "This exercise contains 1 blank.")
  expect_match(result$feedback$message, "Please replace <code>###</code> with valid code.")
})

test_that("setting a regex blank for the blank checker", {
  ex <- mock_exercise(
    user_code       = '..function..("..string..")',
    exercise.blanks = "\\.\\.\\S+?\\.\\."
  )
  result <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE)
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:2")

  expect_match(result$feedback$message, "This exercise contains 2 blanks.")
  expect_match(result$feedback$message, "Please replace <code>..function..</code> and <code>..string..</code> with valid code.")
})

test_that("use underscores as blanks if exercise.blanks is TRUE", {
  ex <- mock_exercise(
    user_code = 'print("____")', exercise.blanks = TRUE
  )
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:1")
  expect_match(result$feedback$message, "This exercise contains 1 blank.")
  expect_match(result$feedback$message, "Please replace <code>____</code> with valid code.")

  ex <- mock_exercise(
    user_code = '____("test")', exercise.blanks = TRUE
  )
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_for_blanks(ex)$feedback)
  expect_match(result$feedback$message, "&quot;count&quot;:1")
  expect_match(result$feedback$message, "This exercise contains 1 blank.")
  expect_match(result$feedback$message, "Please replace <code>____</code> with valid code.")
})

test_that("default message if exercise.blanks is FALSE", {
  ex <- mock_exercise(
    user_code = 'print("____")', exercise.blanks = FALSE
  )
  result <- evaluate_exercise(ex, new.env())
  expect_null(result$feedback$message)
  expect_null(exercise_check_code_for_blanks(ex))

  ex <- mock_exercise(
    user_code = '____("test")', exercise.blanks = FALSE
  )
  result <- evaluate_exercise(ex, new.env())
  expect_null(exercise_check_code_for_blanks(ex))
  expect_match(result$feedback$message, "text.unparsable")
  expect_match(
    result$feedback$message, i18n_translations()$en$translation$text$unparsable,
    fixed = TRUE
  )
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
})


# Unparsable Code ---------------------------------------------------------

test_that("evaluate_exercise() returns a message if code is unparsable", {
  ex <- mock_exercise(user_code = 'print("test"')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsable")
  expect_match(
    result$feedback$message, i18n_translations()$en$translation$text$unparsable,
    fixed = TRUE
  )
  expect_match(result$error_message, "unexpected end of input")

  ex <- mock_exercise(user_code = 'print("test)')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsable")
  expect_match(
    result$feedback$message, i18n_translations()$en$translation$text$unparsable,
    fixed = TRUE
  )
  expect_match(result$error_message, "unexpected INCOMPLETE_STRING")

  ex <- mock_exercise(user_code = 'mean(1:10 na.rm = TRUE)')
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsable")
  expect_match(
    result$feedback$message, i18n_translations()$en$translation$text$unparsable,
    fixed = TRUE
  )
  expect_match(result$error_message, "unexpected symbol")
})

test_that("evaluate_exercise() passes parse error to explicit exercise checker function", {
  ex <- mock_exercise(
    "_foo",
    check = "check",
    error_check = "error_check",
    exercise.error.check.code = "default_error_check"
  )

  res <- evaluate_exercise(ex, new.env())
  expect_equal(res$feedback$checker_args$check_code, "error_check")

  ex$error_check <- NULL
  res <- evaluate_exercise(ex, new.env())
  expect_equal(res$feedback, exercise_check_code_is_parsable(ex)$feedback)
})

test_that("exericse_check_code_is_parsable() gives error checker a 'parse_error' condition", {
  ex <- mock_exercise(user_code = 'print("test"', error_check = I("last_value"))
  result <- evaluate_exercise(ex, new.env())
  expect_s3_class(result$feedback$checker_result, class = c("parse_error", "condition"))
})

test_that("Errors with global setup code result in an internal error", {
  ex <- mock_exercise(global_setup = "stop('boom')")
  expect_warning(
    res <- evaluate_exercise(ex, new.env(), evaluate_global_setup = TRUE),
    "global setup"
  )

  expect_null(res$error_message)
  expect_match(res$feedback$message, "internal error occurred while setting up the tutorial")
  expect_s3_class(res$feedback$error, "simpleError")
  expect_match(conditionMessage(res$feedback$error), "boom")
})

# Unparsable Unicode ------------------------------------------------------

test_that("evaluate_exercise() returns message for unparsable non-ASCII code", {
  # Curly double quotes
  ex <- mock_exercise(
    user_code = "str_detect(\u201ctest\u201d, \u201ct.+t\u201d)"
  )
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsablequotes")
  expect_match(
    result$feedback$message,
    i18n_translations()$en$translation$text$unparsablequotes,
    fixed = TRUE
  )

  # Curly single quotes
  ex <- mock_exercise(
    user_code = "str_detect(\u2018test\u2019, \u2018t.+t\u2019)"
  )
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsablequotes")
  expect_match(
    result$feedback$message,
    i18n_translations()$en$translation$text$unparsablequotes,
    fixed = TRUE
  )

  # En dash
  ex     <- mock_exercise(user_code = "63 \u2013 21")
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsableunicodesuggestion")
  expect_match(
    result$feedback$message,
    i18n_translations()$en$translation$text$unparsableunicodesuggestion,
    fixed = TRUE
  )

  # Plus-minus sign
  ex     <- mock_exercise(user_code = "63 \u00b1 21")
  result <- evaluate_exercise(ex, new.env())
  expect_equal(result$feedback, exercise_check_code_is_parsable(ex)$feedback)
  expect_match(result$feedback$message, "text.unparsableunicode")
  expect_match(
    result$feedback$message,
    i18n_translations()$en$translation$text$unparsableunicode,
    fixed = TRUE
  )
})

test_that("evaluate_exercise() does not return a message for parsable non-ASCII code", {
  skip_on_os("windows")
  # Greek variable name and interrobang in character string
  ex <- mock_exercise(
    user_code =
      '\u03bc\u03b5\u03c4\u03b1\u03b2\u03bb\u03b7\u03c4\u03ae <- "What\u203d"'
  )
  result <- evaluate_exercise(ex, new.env())
  expect_null(result$feedback)
})

# Timelimit ---------------------------------------------------------------

test_that("Exercise timelimit error is returned when exercise takes too long", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")

  ex <- mock_exercise(user_code = "Sys.sleep(3)", exercise.timelimit = 1)

  make_evaluator <- setup_forked_evaluator_factory(max_forked_procs = 1)
  evaluator <- make_evaluator(
    evaluate_exercise(ex, new.env()),
    timelimit = ex$options$exercise.timelimit
  )

  evaluator$start()
  while (!evaluator$completed()) {
    Sys.sleep(1)
  }
  res <- evaluator$result()

  expect_s3_class(res, "learnr_exercise_result")
  expect_true(res$timeout_exceeded)
  expect_match(res$error_message, "permitted timelimit")
  expect_match(as.character(res$html_output), "alert-danger")
})



# Sensitive env vars and options are masked from user -----------------------

test_that("Shiny session is diabled", {
  ex <- mock_exercise(user_code = "shiny::getDefaultReactiveDomain()")

  shiny::withReactiveDomain(list(internal_test = TRUE), {
    expect_equal(shiny::getDefaultReactiveDomain(), list(internal_test = TRUE))
    res <- evaluate_exercise(ex, new.env())
    expect_equal(shiny::getDefaultReactiveDomain(), list(internal_test = TRUE))
  })

  expect_match(res$html_output, "<code>NULL</code>", fixed = TRUE)
})

test_that("Sensitive env vars and options are masked", {
  ex <- mock_exercise(user_code = paste(
    "list(",
    "  Sys.getenv('CONNECT_API_KEY', 'USER_LOCAL_CONNECT_API_KEY'),",
    "  Sys.getenv('CONNECT_SERVER', 'USER_LOCAL_CONNECT_SERVER'),",
    "  getOption('shiny.sharedSecret', 'USER_LOCAL_sharedSecret')",
    ")",
    sep = "\n"
  ))

  env_connect <- list(
    CONNECT_API_KEY = "T_CONNECT_API_KEY",
    CONNECT_SERVER = "T_CONNECT_SERVER"
  )
  opts_shiny <- list(shiny.sharedSecret = "T_sharedSecret")

  withr::with_envvar(env_connect, {
    withr::with_options(opts_shiny, {
      # evaluating the exercise in an env with sentive envvars and options
      res <- evaluate_exercise(ex, new.env())
    })
  })

  expect_no_match(res$html_output, "T_CONNECT_API_KEY", fixed = TRUE)
  expect_no_match(res$html_output, "T_CONNECT_SERVER", fixed = TRUE)
  expect_no_match(res$html_output, "T_sharedSecret", fixed = TRUE)
})

# Exercises in Other Languages --------------------------------------------

test_that("is_exercise_engine()", {
  expect_true(
    is_exercise_engine(list(), "R")
  )
  expect_true(
    is_exercise_engine(list(), "r")
  )
  expect_true(
    is_exercise_engine(list(engine = "R"), "R")
  )
  expect_true(
    is_exercise_engine(list(engine = "sql"), "SQL")
  )
  expect_true(
    is_exercise_engine(list(engine = "JS"), "js")
  )
  expect_false(
    is_exercise_engine(list(), "sql")
  )
  expect_false(
    is_exercise_engine(list(engine = "js"), "sql")
  )
  expect_error(
    is_exercise_engine(NULL)
  )
  expect_error(
    is_exercise_engine()
  )
  expect_error(
    is_exercise_engine(list())
  )
})

test_that("SQL exercises - without explicit `output.var`", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  local_edition(3)

  # example from https://dbi.r-dbi.org/#example
  ex_sql_engine <- mock_exercise(
    user_code = "SELECT * FROM mtcars",
    label = "db",
    chunks = list(
      mock_chunk("db", exercise = TRUE, engine = "sql", code = "SELECT * FROM mtcars", connection = "db_con"),
      mock_chunk(
        "db-setup",
        code = paste(
          c(
            "options(max.print = 25)",
            'db_con <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")',
            'DBI::dbWriteTable(db_con, "mtcars", mtcars)'
          ),
          collapse = "\n"
        )
      )
    ),
    engine = "sql",
    check = I(" ")
  )

  res_sql_engine <- evaluate_exercise(ex_sql_engine, new.env())
  res <- res_sql_engine$feedback$checker_args

  # snapshots
  expect_snapshot(writeLines(exercise_code_chunks_user_rmd(prepare_exercise(ex_sql_engine))))
  expect_snapshot(writeLines(res_sql_engine$html_output))

  # connection exists in envir_prep
  expect_true(exists("db_con", res$envir_prep, inherits = FALSE))
  con <- get("db_con", res$envir_prep, inherits = FALSE)
  expect_true(DBI::dbIsValid(con))
  # we cleaned up the __sql_result object from envir_result
  expect_false(exists("__sql_result", res$envir_result, inherits = FALSE))

  mtcars <- mtcars
  rownames(mtcars) <- NULL
  expect_equal(res$last_value, mtcars)

  DBI::dbDisconnect(con)
})

test_that("SQL exercises - with explicit `output.var`", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  local_edition(3)

  # example from https://dbi.r-dbi.org/#example
  ex_sql_engine <- mock_exercise(
    user_code = "SELECT * FROM mtcars",
    label = "db",
    chunks = list(
      mock_chunk(
        "db",
        exercise = TRUE,
        engine = "sql",
        code = "SELECT * FROM mtcars",
        connection = "db_con",
        output.var = "my_result"
      ),
      mock_chunk(
        "db-setup",
        code = paste(
          c(
            "options(max.print = 25)",
            'db_con <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")',
            'DBI::dbWriteTable(db_con, "mtcars", mtcars)'
          ),
          collapse = "\n"
        )
      )
    ),
    engine = "sql",
    check = I(" ")
  )

  res_sql_engine <- evaluate_exercise(ex_sql_engine, new.env())
  res <- res_sql_engine$feedback$checker_args

  # snapshots
  expect_snapshot(writeLines(exercise_code_chunks_user_rmd(prepare_exercise(ex_sql_engine))))
  expect_snapshot(writeLines(format(res_sql_engine$html_output)))

  # connection exists in envir_prep
  expect_true(exists("db_con", res$envir_prep, inherits = FALSE))
  con <- get("db_con", res$envir_prep, inherits = FALSE)
  expect_true(DBI::dbIsValid(con))
  # we left the sql result in `envir_result`
  expect_true(exists("my_result", res[["envir_result"]], inherits = FALSE))
  expect_equal(res[["last_value"]], res[["envir_result"]][["my_result"]])

  mtcars <- mtcars
  rownames(mtcars) <- NULL
  expect_equal(res$last_value, mtcars)

  DBI::dbDisconnect(con)
})
