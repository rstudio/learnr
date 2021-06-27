
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

test_that("render_exercise() cleans up exercise_prep files", {
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
  exercise <- mock_exercise(
    user_code = c("writeLines('nope', 'nope.txt')", "dir()"),
    # setup chunk throws an error
    chunks = list(mock_chunk("ex-setup", c("dir_setup <- dir()", "stop('boom')"))),
    # get file listing after error in setup chunk happens
    error_check = I("dir()")
  )

  files <- expect_message(
    withr::with_tempdir({
      before <-  dir()
      res <- render_exercise(exercise, new.env())
      list(
        before = before,
        before_error = get("dir_setup", res$feedback$checker_args$envir_prep),
        during = res$feedback$checker_result,
        after = dir()
      )
    }),
    "exercise_prep.Rmd"
  )

  # start with nothing
  expect_identical(files$before, character(0))
  # prep file is present while evaluating prep
  expect_identical(files$before_error, "exercise_prep.Rmd")
  # prep files are cleaned up after error
  expect_identical(files$during, character(0))
  # nothing in directory after render_exercise() because user code didn't evaluate
  expect_identical(files$after, character(0))
})

test_that("render_exercise() warns if exercise setup overwrites exercise.Rmd", {
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

# unparsable input -----------------------------------------------------------

test_that("evaluate_exercise() returns a message if code contains ___", {
  ex     <- mock_exercise(user_code = '____("test")')
  result <- evaluate_exercise(ex, new.env())
  expect_match(result$error_message, "contains 1 blank")

  ex     <- mock_exercise(user_code = '____("____")')
  result <- evaluate_exercise(ex, new.env())
  expect_match(result$error_message, "contains 2 blanks")
})

est_that("evaluate_exercise() returns a message if code is unparsable", {
  ex     <- mock_exercise(user_code = 'print("test"')
  result <- evaluate_exercise(ex, new.env())
  expect_match(result$error_message, "this might not be valid R code")

  ex     <- mock_exercise(user_code = 'print("test)')
  result <- evaluate_exercise(ex, new.env())
  expect_match(result$error_message, "this might not be valid R code")

  ex     <- mock_exercise(user_code = 'mean(1:10 na.rm = TRUE)')
  result <- evaluate_exercise(ex, new.env())
  expect_match(result$error_message, "this might not be valid R code")
})
