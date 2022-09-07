current_exercise_version <- "4"

# Shiny Exercise Handling -------------------------------------------------

cache_complete_exercise <- function(exercise) {
  exercise_full <- get_exercise_cache(exercise$label)
  exercise <- append(exercise, exercise_full)
  class(exercise) <- class(exercise_full)
  exercise
}

# run an exercise and return HTML UI
setup_exercise_handler <- function(exercise_rx, session) {

  # get the environment where shared setup and data is located. one environment up
  # includes all of the shiny housekeeping (e.g. inputs, output, etc.); two
  # environments up will be an empty environment
  # (https://github.com/rstudio/rmarkdown/blob/54bf8fc70122c6a435bba2ffcac8944d04498541/R/shiny_prerendered.R#L10)
  # that is parented by the shiny_prerendered server_envir (which has all of
  # the shared setup, data chunks executed).
  server_envir <- parent.env(parent.env(parent.frame()))

  # setup reactive values for return
  rv <- reactiveValues(triggered = 0, result = NULL)

  # observe input
  observeEvent(exercise_rx(), {

    # get exercise from app
    exercise <- exercise_rx()
    # Add tutorial information
    exercise$tutorial <- get_tutorial_info()
    # Remove tutorial items from exercise object
    exercise$tutorial$items <- NULL

    # short circuit for restore (we restore some outputs like errors so that
    # they are not re-executed when bringing the tutorial back up)
    if (exercise$restore) {
      if (
        getOption(
          "tutorial.quick_restore",
          identical(Sys.getenv("TUTORIAL_QUICK_RESTORE", "0"), "1")
        )
      ) {
        # don't evaluate at all if quick_restore is enabled
        rv$result <- list()
        return()
      }

      object <- get_exercise_submission(session = session, label = exercise$label)
      if (!is.null(object) && !is.null(object$data$output)) {
        # restore user state, but don't report correct
        # since the user's code wasn't re-evaluated
        restored_state <- list(
          type = "exercise",
          answer = object$data$code,
          correct = NA
        )
        set_tutorial_state(exercise$label, restored_state, session = session)

        # get the output
        output <- object$data$output

        # ensure that html dependencies only reference package files
        dependencies <- htmltools::htmlDependencies(output)
        if (!is.null(dependencies))
          htmltools::htmlDependencies(output) <- filter_dependencies(dependencies)

        # assign to rv and return
        rv$result <- output
        return()
      }
    }

    # get exercise evaluator factory function (allow replacement via global option)
    evaluator_factory <- getOption("tutorial.exercise.evaluator", default = NULL)
    if (is.null(evaluator_factory)) {
      remote_host <- getOption("tutorial.external.host", Sys.getenv("TUTORIAL_EXTERNAL_EVALUATOR_HOST", NA))
      if (!is.na(remote_host)){
        evaluator_factory <- external_evaluator(remote_host)
      } else if (!is_windows() && !is_mac())
        evaluator_factory <- forked_evaluator_factory
      else
        evaluator_factory <- inline_evaluator
    }

    # retrieve exercise cache information:
    # - chunks (setup + exercise) for the exercise to be processed in `evaluate_exercise`
    # - checker code (check, code-check, error-check)
    # - solution
    # - engine
    exercise <- cache_complete_exercise(exercise)

    check_was_requested <- exercise$should_check
    # remove "should_check" item from exercise for legacy reasons, it's inferred downstream
    exercise$should_check <- NULL

    if (!isTRUE(check_was_requested)) {
      exercise$check <- NULL
      exercise$code_check <- NULL
      exercise$error_check <- NULL
    }

    # get timelimit option (either from chunk option or from global option)
    timelimit <- exercise$options$exercise.timelimit
    if (is.null(timelimit))
      timelimit <- getOption("tutorial.exercise.timelimit", default = 30)

    # placeholder for current learnr version to deal with exercise structure differences
    # with other learnr versions
    exercise$version <- current_exercise_version

    # create a new environment parented by the global environment
    # transfer all of the objects in the server_envir (i.e. setup and data chunks)
    envir <- duplicate_env(server_envir, parent = globalenv())
    if (exists(".server_context", envir = envir)) {
      rm(".server_context", envir = envir)
    }

    # create exercise evaluator
    evaluator <- evaluator_factory(evaluate_exercise(exercise, envir),
                                   timelimit, exercise, session)

    # Create exercise ID to map the associated events.
    ex_id <- random_id("lnr_ex")

    # fire event before computing
    event_trigger(
      session,
      "exercise_submitted",
      data = list(
        label   = exercise$label,
        id      = ex_id,
        code    = exercise$code,
        restore = exercise$restore
      )
    )

    start <- Sys.time()

    # start it
    evaluator$start()

    # poll for completion
    o <- observe({

      if (evaluator$completed()) {

        # get the result
        result <- evaluator$result()

        # fire event with evaluation result
        event_trigger(
          session,
          "exercise_result",
          data = list(
            label            = exercise$label,
            id               = ex_id,
            code             = exercise$code,
            output           = result$html_output,
            timeout_exceeded = result$timeout_exceeded,
            time_elapsed     = as.numeric(difftime(Sys.time(), start, units="secs")),
            error_message    = result$error_message,
            checked          = check_was_requested,
            feedback         = result$feedback
          )
        )

        # assign reactive result to be sent to the UI
        rv$triggered <- isolate({ rv$triggered + 1})
        rv$result <- exercise_result_as_html(result)

        isolate({
          # update the user_state with this submission, matching the behavior of
          # questions: always update exercises until correct answer is submitted
          current_state <- get_tutorial_state(exercise$label, session = session)
          if (!isTRUE(current_state$correct)) {
            new_state <- list(
              type = "exercise",
              answer = exercise$code,
              correct = result$feedback$correct %||% NA
            )
            set_tutorial_state(exercise$label, new_state, session = session)
          }
        })


        # destroy the observer
        o$destroy()

      } else {
        invalidateLater(100, session)
      }
    })
  })

  # return reactive
  reactive({
    rv$triggered
    req(rv$result)
  })
}

# Validation and Standardization ------------------------------------------

# This function exists to synchronize versions of the exercise objects in case
# an exercise created with an older version of {learnr} is evaluated by a
# newer version of {learnr}. This may be the case when there is a version
# mismatch between the version used to serve the tutorial and the version used
# to evaluate the exercise (external evaluator).
upgrade_exercise <- function(exercise, require_items = NULL) {
  prepend_engine_class <- function(exercise) {
    class(exercise) <- c(
      setdiff(union(exercise$engine, class(exercise)), "tutorial_exercise"),
      "tutorial_exercise"
    )
    exercise
  }

  if (identical(exercise$version, current_exercise_version)) {
    return(prepend_engine_class(exercise))
  }

  if (!is.null(exercise$version)) {
    exercise$version <- suppressWarnings(as.numeric(exercise$version))
  }

  if (
    is.null(exercise$version) ||
      is.na(exercise$version) ||
      length(exercise$version) != 1 ||
      identical(paste(exercise$version), "0")
  ) {
    v <- if (is.null(exercise$version)) {
      "an undefined version"
    } else if (is.na(exercise$version) || length(exercise$version) != 1) {
      "an incorrectly formatted version"
    } else {
      'version "0"'
    }

    stop(
      "Received an exercise with ", v, ", most likely because it's ",
      "from an older version of {learnr}. This is {learnr} version ",
      utils::packageVersion("learnr")
    )
  }

  current_version <- as.numeric(current_exercise_version)

  if (exercise$version == 1) {
    # upgrade from version 1 to version 2
    # exercise version 2 added $tutorial information
    exercise$tutorial <- list(
      tutorial_id = "tutorial_id:UPGRADE learnr",
      tutorial_version = "-1",
      user_id = "user_id:UPGRADE learnr"
    )
    exercise$version <- 2
  }

  if (exercise$version == 2) {
    # upgrade from version 2 to version 3
    # => add language $tutorial information
    exercise$tutorial$language <- i18n_get_language_option()
    exercise$version <- 3
  }

  if (exercise$version == 3) {
    # upgrade from version 3 to version 4
    # => exercise class now includes engine (first) and `tutorial_exercise` (last)
    exercise <- prepend_engine_class(exercise)
    exercise$version <- 4
  }

  # Future logic to upgrade an exercise from version 4 to version N goes here...

  if (identical(exercise$version, current_version)) {
    return(exercise)
  }

  # What if we get an exercise from the future? We'll try to have backwards
  # compatibility with the exercise object. But validate_exercise() will find
  # any catastrophic problems that are incompatible with the _current_ version
  exercise_problem <- validate_exercise(exercise, require_items)

  if (is.null(exercise_problem)) {
    # The exercise may not evaluate perfectly, but it's likely that evaluating
    # this exercise will work out. Or at least won't result in surfacing an
    # internal learnr error as the culprit.
    warning(
      "Expected exercise version ", current_version, ", but received version ",
      exercise$version, ". This version of {learnr} is likely able to evaluate ",
      "version ", exercise$version, " exercises, but there may be differences. ",
      "Please upgrade {learnr}; this version is ",
      utils::packageVersion("learnr"), "."
    )
    return(exercise)
  }

  stop(
    "Expected exercise version ", current_version, ", but received version ",
    exercise$version, ". These versions are incompatible. ", exercise_problem
  )
}

# The current version of the exercise object will produce _very wrong_ or _very
# surprising_ results if it doesn't pass this validation check. This function
# returns NULL if everything is okay, otherwise a character string describing
# the reason the validation check failed.
validate_exercise <- function(exercise, require_items = NULL) {
  required_names <- c("code", "label", "options", "chunks", require_items)
  missing_names <- setdiff(required_names, names(exercise))
  if (length(missing_names)) {
    return(paste("Missing exercise items:", paste(missing_names, collapse = ", ")))
  }

  NULL
}

standardize_code <- function(code) {
  if (is_AsIs(code)) {
    return(code)
  }
  if (is.null(code) || !length(code)) {
    return("")
  }
  # convert CRLF to POSIX line endings
  code <- gsub("\r\n", "\n", code, fixed = TRUE)
  str_trim(paste0(code, collapse = "\n"))
}

standardize_exercise_code <- function(exercise) {
  ex_code_items <- c("error_check", "code_check", "check", "code", "global_setup", "solution", "tests")
  exercise[ex_code_items] <- lapply(exercise[ex_code_items], standardize_code)
  exercise
}

# Evaluate Exercise -------------------------------------------------------

# evaluate an exercise and return a list containing output and dependencies
# @param evaluate_global_setup - If `FALSE`, will not evaluate the global setup
#   code. Instead, it just concatenates the exercise- specific setup code and
#   then the submitted exercise code itself into the resultant expression. If
#   `TRUE`, it will evaluate global exercise setup chunk
#   (`setup-global-exercise` or `setup`) prior to running the checker. Local
#   evaluators inherit an environment in which those setup chunks have already
#   been executed, so they'd typically use `FALSE`, the default. Remote
#   evaluators, if they choose to use this function, might want to include the
#   global setup.
evaluate_exercise <- function(
  exercise, envir, evaluate_global_setup = FALSE, data_dir = NULL
) {

  # Exercise Prep and Standardization ---------------------------------------
  # Protect global options and environment vars from permanent modification
  local_restore_options_and_envvars()

  # adjust exercise version to match the current learnr version
  exercise <- upgrade_exercise(
    exercise,
    require_items = if (evaluate_global_setup) "global_setup"
  )

  # standardize exercise code to single string (code, *check, global_setup)
  exercise <- standardize_exercise_code(exercise)
  exercise$envir <- envir

  i18n_set_language_option(exercise$tutorial$language)

  if (!nzchar(exercise$code)) {
    # return immediately and clear visible results - do not consider this an
    # exercise submission but return " " since html_output needs to pass a req()
    return(exercise_result(html_output = " "))
  }

  # Evaluate Global Setup ---------------------------------------------------
  if (evaluate_global_setup) {
    res_global <-
      tryCatch({
        eval(parse(text = exercise$global_setup), envir = envir)
        NULL
      }, error = function(err) {
        exercise_result_error_internal(
          exercise,
          err,
          task_internal = "evaluating the global setup",
          task_external = "setting up the tutorial"
        )
      })

    if (is_exercise_result(res_global)) {
      return(res_global)
    }
  }

  # Check if user code has unfilled blanks ----------------------------------
  # If blanks are detected we store the feedback for use at the standard
  # feedback-returning exit points, but still try to render the user code since
  # the output may still be valid even if the user needs to fill in some blanks.
  # Importantly, `blank_feedback` is `NULL` if no blanks are detected.
  blank_feedback <- exercise_check_code_for_blanks(exercise)

  here <- rlang::current_env()
  return_if_exercise_result <- function(res) {
    # early return if we've received an exercise result, but also replace the
    # feedback with the blank feedback if any blanks were found
    if (!is_exercise_result(res)) {
      return()
    }

    if (!is.null(blank_feedback$feedback)) {
      res$feedback <- blank_feedback$feedback
    }

    rlang::return_from(here, res)
  }

  # Check that user R code is parsable -------------------------------------
  if (is_exercise_engine(exercise, "r")) {
    return_if_exercise_result(
      exercise_check_code_is_parsable(exercise)
    )
  }

  # Code check, pre-evaluation ---------------------------------------------
  if (nzchar(exercise$code_check)) {
    # treat the blank check like a code check, if blanks were detected
    return_if_exercise_result(blank_feedback)

    return_if_exercise_result(
      try_checker(
        exercise,
        stage = "code_check",
        check_code = exercise$code_check,
        envir_prep = duplicate_env(envir)
      )
    )
  }

  # Render user code --------------------------------------------------------
  # Setup a temporary directory for rendering the exercise
  exercise_dir <- withr::local_tempdir(pattern = "lrn-ex")

  # Copy files from data directory into exercise
  copy_data_dir(data_dir, exercise_dir)

  # Move into the temp exercise directory for evaluation and checking
  withr::local_dir(exercise_dir)

  # Evaluate the submitted code by rendering the exercise in a special .Rmd
  rmd_results <- tryCatch(
    render_exercise(exercise, envir),
    error = function(err_render) {
      if (!inherits(err_render, "learnr_render_exercise_error")) {
        # render exercise errors are expected, but something really went wrong
        return(
          exercise_result_error_internal(exercise, err_render, "evaluating your exercise", "inside render_exercise()")
        )
      }
      error_feedback <- NULL
      error_check_code <- exercise$error_check
      error_should_check <- nzchar(exercise$check) || nzchar(exercise$code_check)
      if (error_should_check && !nzchar(error_check_code)) {
        # If there is no locally defined error check code, look for globally defined error check option
        error_check_code <- standardize_code(exercise$options$exercise.error.check.code)
      }
      if (nzchar(error_check_code)) {
        # Error check -------------------------------------------------------
        # Check the error thrown by the submitted code when there's error
        # checking: the exercise could be to throw an error!
        error_feedback <- try_checker(
          exercise,
          stage = "error_check",
          check_code = error_check_code,
          envir_result = err_render$envir_result,
          evaluate_result = err_render$evaluate_result,
          envir_prep = err_render$envir_prep,
          last_value = err_render$parent
        )
      }
      exercise_result_error(
        error_message = conditionMessage(err_render$parent),
        feedback = error_feedback$feedback
      )
    }
  )

  return_if_exercise_result(rmd_results)

  if (!is.null(blank_feedback)) {
    # No further checking required if we detected blanks
    return(
      exercise_result(
        feedback = blank_feedback$feedback,
        html_output = rmd_results$html_output
      )
    )
  }

  # Check -------------------------------------------------------------------
  # Run the checker post-evaluation (for checking results of evaluated code)
  checker_feedback <-
    if (nzchar(exercise$check)) {
      try_checker(
        exercise,
        stage = "check",
        check_code = exercise$check,
        envir_result = rmd_results$envir_result,
        evaluate_result = rmd_results$evaluate_result,
        envir_prep = rmd_results$envir_prep,
        last_value = rmd_results$last_value
      )
    }

  exercise_result(
    feedback = checker_feedback$feedback,
    html_output = rmd_results$html_output
  )
}


try_checker <- function(
  exercise, stage,
  name = "exercise.checker", check_code = NULL, envir_result = NULL,
  evaluate_result = NULL, envir_prep, last_value = NULL,
  engine = exercise$engine
) {
  checker_func <- tryCatch(
    get_checker_func(exercise, name, envir_prep),
    error = function(e) {
      message("Error occurred while retrieving '", name, "'. Error:\n", e)
      exercise_result_error(e$message)
    }
  )
  # If retrieving checker_func fails, return an error result
  if (is_error_result(checker_func)) {
    rlang::return_from(rlang::caller_env(), checker_func)
  }
  checker_args <- names(formals(checker_func))
  args <- list(
    label = exercise$label,
    user_code = exercise$code,
    solution_code = exercise$solution,
    check_code = check_code,
    envir_result = envir_result,
    evaluate_result = evaluate_result,
    envir_prep = envir_prep,
    last_value = last_value,
    engine = engine,
    stage = stage
  )
  # Throw better error messaging if the checker function signature is ill-defined
  missing_args <- setdiff(names(args), checker_args)
  if (length(missing_args) && !"..." %in% checker_args) {
    if (identical(missing_args, "stage")) {
      # Don't throw an error if the only missing argument is `stage`.
      # `stage` was not available in learnr <= 0.10.1 and checker functions can
      #   still work without it.
      args <- args[names(args) != "stage"]
    } else {
      msg <- sprintf(
        "Either add ... or the following arguments to the '%s' function: '%s'",
        name, paste(missing_args, collapse = "', '")
      )
      message(msg)
      rlang::return_from(rlang::caller_env(), exercise_result_error(msg))
    }
  }

  # Call the check function
  feedback <- tryCatch(
    do.call(checker_func, args),
    error = function(e) {
      msg <- paste("Error occurred while evaluating", sprintf("'%s'", name))
      message(msg, ": ", conditionMessage(e))
      exercise_result_error(msg)
    }
  )
  # If checker code fails, return an error result
  if (is_error_result(feedback)) {
    rlang::return_from(rlang::caller_env(), feedback)
  }
  # If checker doesn't return anything, there's no exercise result to return
  if (length(feedback)) {
    exercise_result(feedback)
  } else {
    feedback
  }
}

get_checker_func <- function(exercise, name, envir) {
  func <- exercise$options[[name]]
  # attempt to parse the exercise.checker and return the function
  # with envir attached to it.
  checker <- eval(parse(text = func), envir = envir)
  if (is.function(checker)) {
    environment(checker) <- envir
    return(checker)
  } else if(!is.null(checker)) {
    warning("Ignoring the ", name, " option since it isn't a function", call. = FALSE)
  }
  function(...) NULL
}

# Render Exercise ---------------------------------------------------------

render_exercise <- function(exercise, envir) {
  # Protect global options and environment vars from modification by student
  local_restore_options_and_envvars()

  # Make sure exercise (& setup) chunk options and code are prepped for rendering
  exercise <- render_exercise_prepare(exercise)

  # TODO: Refactor `output_format_exercise()` so that we can decouple it from
  # the `output_format` arguments in `render_exercise_evaluate_{prep,user}()`.
  #
  # capture the last value and use a regular output handler for value
  # https://github.com/r-lib/evaluate/blob/e81ba2ba181827a86525767371e6dfdeb364c8b7/R/output.r#L54-L56
  # @param value Function to handle the values returned from evaluation. If it
  #   only has one argument, only visible values are handled; if it has more
  #   arguments, the second argument indicates whether the value is visible.
  last_value <- NULL
  last_value_is_visible <- TRUE
  evaluate_result <- NULL

  # Put the exercise in a minimal HTML doc
  output_format_exercise <- function(user = FALSE) {
    # start constructing knitr_options for the output format
    knitr_options <- exercise["opts_chunk"]

    if (isTRUE(user)) {
      knitr_options$knit_hooks$evaluate <- function(
        code, envir, ..., output_handler # knitr's output_handler
      ) {
        has_visible_arg <- length(formals(output_handler$value)) > 1
        # wrap `output_handler$value` to be able to capture the `last_value`
        # while maintaining the original functionality of `output_handler$value`
        output_handler_value_fn <- output_handler$value
        output_handler$value <- function(x, visible) {
          last_value <<- x
          last_value_is_visible <<- visible

          if (has_visible_arg) {
            output_handler_value_fn(x, visible)
          } else {
            if (visible) {
              output_handler_value_fn(x)
            } else {
              invisible()
            }
          }
        }
        evaluate_result <<- evaluate::evaluate(
          code, envir, ...,
          output_handler = output_handler
        )
        evaluate_result
      }
    }

    rmarkdown::output_format(
      knitr = knitr_options,
      pandoc = NULL,
      base_format = rmarkdown::html_fragment(
        df_print = exercise$options$exercise.df_print,
        pandoc_args = c("--metadata", "title=PREVIEW")
      )
    )
  }

  # Set up prep and result environments (both will be modified during render)
  envir_prep <- duplicate_env(envir)
  envir_result <- envir_prep

  # First, Rmd to markdown (and exit early if any error)
  output_file <- tryCatch({
    # — Render Exercise Stage: Prep ----
    # TODO: The render stage and everything associated with it should really be
    #       named "setup", e.g. `envir_setup`, etc. The stage here is called
    #       "prep" to avoid confusion with the current naming.
    render_stage <- "prep"

    render_exercise_evaluate_prep(
      exercise = exercise,
      envir_prep = envir_prep,
      output_format_exercise(user = FALSE)
    )

    # Create exercise.Rmd after running setup so it isn't accidentally overwritten
    if (file.exists("exercise.Rmd")) {
      warning(
        "Evaluating user code in exercise '", exercise$label, "' created ",
        "'exercise.Rmd'. If the setup code for this exercise creates a file ",
        "with that name, please choose another name.",
        immediate. = TRUE
      )
    }

    # — Render Exercise Stage: User ----
    render_stage <- "user"
    # Copy in a full clone `envir_prep` before running user code in `envir_result`
    # By being a sibling to `envir_prep` (rather than a dependency),
    # alterations to `envir_prep` from eval'ing code in `envir_result`
    # are much more difficult
    envir_result <- render_exercise_duplicate_env(exercise, envir_prep)

    render_exercise_evaluate_user(
      exercise = exercise,
      envir_result = envir_result,
      output_format_exercise(user = TRUE)
    )
  }, error = function(e) {
    msg <- conditionMessage(e)
    # make the time limit error message a bit more friendly
    pattern <- gettext("reached elapsed time limit", domain = "R")
    if (grepl(pattern, msg, fixed = TRUE)) {
      return(exercise_result_timeout())
    }

    if (render_stage == "prep") {
      # errors in setup (prep) code should be returned as internal error results
      return(
        exercise_result_error_internal(
          exercise = exercise,
          error = e,
          task_external = "setting up the exercise",
          task_internal = "rendering exercise setup"
        )
      )
    }

    rlang::abort(
      class = "learnr_render_exercise_error",
      envir_result = envir_result,
      evaluate_result = evaluate_result,
      envir_prep = envir_prep,
      parent = e
    )
  })

  if (is_exercise_result(output_file)) {
    # this only happens when the render result is a timeout error or setup error
    return(output_file)
  }

  # Render markdown to HTML
  dependencies <- filter_dependencies(attr(output_file, "knit_meta"))
  output_file <- rmarkdown::render(
    input = output_file, output_format = output_format_exercise(user = TRUE),
    envir = envir_result, quiet = TRUE, clean = FALSE
  )
  output <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
  html_output <- htmltools::attachDependencies(
    htmltools::HTML(paste(output, collapse = "\n")),
    dependencies
  )

  if (!last_value_is_visible && isTRUE(exercise$options$exercise.warn_invisible)) {
    invisible_feedback <- list(
      message = "The submitted code didn't produce a visible value, so exercise checking may not work correctly.",
      type = "warning", correct = FALSE
    )
    html_output <- htmltools::tagList(
      feedback_as_html(invisible_feedback),
      html_output
    )
  }

  render_exercise_result(
    exercise = exercise,
    envir_render = envir,
    envir_prep = envir_prep,
    envir_result = envir_result,
    evaluate_result = evaluate_result,
    last_value = last_value,
    html_output = html_output
  )
}

render_exercise_evaluate_prep <- function(exercise, envir_prep, output_format) {
  withr::defer(render_exercise_post_stage_hook(exercise, "prep", envir_prep))

  rmd_src_prep <- render_exercise_rmd_prep(exercise)

  if (length(rmd_src_prep) > 0) {
    rmd_file_prep <- "exercise_prep.Rmd"
    writeLines(rmd_src_prep, con = rmd_file_prep, useBytes = TRUE)
    on.exit(unlink(dir(pattern = "exercise_prep")), add = TRUE)

    # First pass without user code to get envir_prep
    rmd_file_prep_html <- rmarkdown::render(
      input = rmd_file_prep,
      output_format = output_format,
      envir = envir_prep,
      clean = TRUE,
      quiet = TRUE,
      run_pandoc = FALSE
    )
  }
}

render_exercise_evaluate_user <- function(exercise, envir_result, output_format) {
  withr::defer(render_exercise_post_stage_hook(exercise, "user", envir_result))

  rmd_src_user <- render_exercise_rmd_user(exercise)
  rmd_file_user <- "exercise.Rmd"
  writeLines(rmd_src_user, con = rmd_file_user, useBytes = TRUE)

  with_masked_env_vars(
    # Now render user code for final result
    rmarkdown::render(
      input = rmd_file_user,
      output_format = output_format,
      envir = envir_result,
      clean = FALSE,
      quiet = TRUE,
      run_pandoc = FALSE
    )
  )
}

# Exercise Chunk Helpers --------------------------------------------------

exercise_get_chunks <- function(exercise, type = c("all", "prep", "user")) {
  type <- match.arg(type)
  if (type == "all") {
    return(exercise$chunks)
  }
  is_user_chunk <- vapply(
    exercise$chunks,
    function(chunk) identical(chunk$label, exercise$label),
    logical(1)
  )
  if (type == "prep") {
    exercise$chunks[!is_user_chunk]
  } else {
    exercise$chunks[is_user_chunk]
  }
}

exercise_code_chunks_prep <- function(exercise) {
  exercise_code_chunks(exercise_get_chunks(exercise, "prep"))
}

exercise_code_chunks_user <- function(exercise) {
  user_chunk <- exercise_get_chunks(exercise, "user")
  exercise_code_chunks(user_chunk)
}

exercise_code_chunks <- function(chunks) {
  vapply(chunks, function(x) {
    opts <- x$opts[setdiff(names(x$opts), "label")]
    opts <- paste(names(opts), unname(opts), sep = "=")
    paste(
      sep = "\n",
      # we quote the label to ensure that it is treated as a label and not a symbol for instance
      sprintf("```{%s %s}", x$engine, paste0(c(dput_to_string(x$label), opts), collapse = ", ")),
      paste0(x$code, collapse = "\n"),
      "```"
    )
  }, character(1))
}

exercise_get_blanks_pattern <- function(exercise) {
  exercise_blanks_opt <-
    exercise$options$exercise.blanks %||%
    knitr::opts_chunk$get("exercise.blanks") %||%
    TRUE

  if (isTRUE(exercise_blanks_opt)) {
    # TRUE is a stand-in for the default ___+
    return("_{3,}")
  }

  exercise_blanks_opt
}

# Exercise Check Helpers --------------------------------------------------

exercise_check_code_for_blanks <- function(exercise) {
  blank_regex <- exercise_get_blanks_pattern(exercise)

  if (!shiny::isTruthy(blank_regex)) {
    return(NULL)
  }

  blank_regex <- paste(blank_regex, collapse = "|")

  user_code <- exercise$code
  blanks <- str_match_all(user_code, blank_regex)

  if (!length(blanks)) {
    return(NULL)
  }

  # default message is stored in data-raw/i18n_translations.yml
  i18n_text <- i18n_translations()$en$translation$text

  text_blanks <- gsub(
    "$t(text.blank)",
    ngettext(length(blanks), "blank", "blanks"),
    i18n_text$exercisecontainsblank,
    fixed = TRUE
  )
  text_blanks <- gsub("{{count}}", length(blanks), text_blanks, fixed = TRUE)

  text_please <- gsub(
    "{{blank}}",
    knitr::combine_words(unique(blanks), before = "<code>", after = "</code>"),
    i18n_text$pleasereplaceblank,
    fixed = TRUE
  )

  msg <- paste(
    i18n_span(
      HTML(text_blanks),
      key = "text.exercisecontainsblank",
      opts = list(count = length(blanks))
    ),
    i18n_span(
      HTML(text_please),
      key = "text.pleasereplaceblank",
      opts = list(
        count = length(blanks),
        blank = i18n_combine_words(unique(blanks), before = "<code>", after = "</code>"),
        interpolation = list(escapeValue = FALSE)
      )
    )
  )

  exercise_result(
    list(message = HTML(msg), correct = FALSE, location = "prepend", type = "error")
  )
}

exercise_check_code_is_parsable <- function(exercise) {
  error <- rlang::catch_cnd(parse(text = exercise$code), "error")
  if (!inherits(error, "error")) {
    return(NULL)
  }

  # Make "parse_error"s identifiable in the error checker
  class(error) <- c("parse_error", class(error))

  # apply the error checker (if explicitly provided) to the parse error
  if (nzchar(exercise$error_check %||% "")) {
    error_feedback <- try_checker(
      exercise,
      stage = "error_check",
      check_code = exercise[["error_check"]],
      envir_result = exercise[["envir"]],
      evaluate_result = error,
      envir_prep = exercise[["envir"]],
      last_value = error
    )

    if (is_exercise_result(error_feedback)) {
      # we have feedback from the error checker so we return the original parse
      # error with the feedback from the error checker
      return(
        exercise_result_error(
          conditionMessage(error),
          error_feedback[["feedback"]]
        )
      )
    }
  }

  default_message <- i18n_span(
    "text.unparsable",
    HTML(i18n_translations()$en$translation$text$unparsable)
  )
  unicode_message <- exercise_check_unparsable_unicode(exercise, error$message)

  feedback <- list(
    message = HTML(unicode_message %||% default_message),
    correct = FALSE,
    location = "append",
    type = "error"
  )

  exercise_result_error(error$message, feedback)
}

exercise_check_unparsable_unicode <- function(exercise, error_message) {
  code <- exercise[["code"]]

  # Early exit if code is made up of all ASCII characters ----------------------
  if (!grepl("[^\\x00-\\x7F]", code, perl = TRUE)) {
    return(NULL)
  }

  # Determine line with offending character based on error message -------------
  line <- as.integer(str_replace(error_message, "<text>:(\\d+):.+", "\\1"))

  # Check if code contains Unicode quotation marks -----------------------------
  single_quote_pattern <- "[\u2018\u2019\u201A\u201B\u275B\u275C\uFF07]"
  double_quote_pattern <- "[\u201C-\u201F\u275D\u275E\u301D-\u301F\uFF02]"
  quote_pattern <- paste(single_quote_pattern, double_quote_pattern, sep = "|")

  if (grepl(quote_pattern, code)) {
    # Replace curly single quotes with straight single quotes and
    #   all other Unicode quotes with straight double quotes
    replacement_pattern <- c("'", '"')
    names(replacement_pattern) <- c(single_quote_pattern, double_quote_pattern)

    return(
      unparsable_unicode_message("unparsablequotes", code, line, quote_pattern, replacement_pattern)
    )
  }

  # Check if code contains Unicode dashes --------------------------------------
  # Regex searches for all characters in Unicode's general category
  #   "Dash_Punctuation", except for the ASCII hyphen-minus
  #   (https://www.unicode.org/reports/tr44/#General_Category_Values)
  dash_pattern <- paste0(
    "[\u00af\u05be\u06d4\u1400\u1428\u1806\u1b78\u2010-\u2015\u203e\u2043",
    "\u2212\u23af\u23e4\u2500\u2796\u2e3a\u2e3b\u30fc\ufe58\ufe63\uff0d]"
  )

  if (grepl(dash_pattern, code)) {
    # Replace Unicode dashes with ASCII hyphen-minus
    replacement_pattern <- "-"
    names(replacement_pattern) <- dash_pattern

    return(
      unparsable_unicode_message("unparsableunicodesuggestion", code, line, dash_pattern, replacement_pattern)
    )
  }

  # Check if code contains any other non-ASCII characters ----------------------
  # Regex searches for any codepoints not in the ASCII range (00-7F)
  non_ascii_pattern <- "[^\u01-\u7f]"
  return(
    unparsable_unicode_message("unparsableunicode", code, line, non_ascii_pattern)
  )
}

unparsable_unicode_message <- function(i18n_key, code, line, pattern, replacement_pattern = NULL) {
  code <- unlist(strsplit(code, "\n"))[[line]]

  character <- str_extract(code, pattern)
  highlighted_code <- exercise_highlight_unparsable_unicode(code, pattern, line)

  suggestion <- NULL
  if (!is.null(replacement_pattern)) {
    suggestion <- html_code_block(str_replace_all(code, replacement_pattern))
  }

  i18n_div(
    paste0("text.", i18n_key),
    HTML(i18n_translations()$en$translation$text[[i18n_key]]),
    opts = list(
      character = character,
      code = highlighted_code,
      suggestion = suggestion,
      interpolation = list(escapeValue = FALSE)
    )
  )
}

exercise_highlight_unparsable_unicode <- function(code, pattern, line) {
  highlighted_code <- gsub(
    pattern = paste0("(", pattern, ")"),
    replacement = "<mark>\\1</mark>",
    x = code
  )

  html_code_block(paste0(line, ": ", highlighted_code), escape = FALSE)
}

# Exercise Result Helpers -------------------------------------------------

exercise_result_timeout <- function() {
  exercise_result_error(
    "Error: Your code ran longer than the permitted timelimit for this exercise.",
    timeout_exceeded = TRUE,
    style = "alert"
  )
}

# @param timeout_exceeded represents whether or not the error was triggered
#   because the exercise exceeded the timeout. Use NA if unknown
exercise_result_error <- function(error_message, feedback = NULL, timeout_exceeded = NA, style = "code") {
  exercise_result(
    feedback = feedback,
    timeout_exceeded = timeout_exceeded,
    error_message = error_message,
    html_output = error_message_html(error_message, style = style)
  )
}

exercise_result_error_internal <- function(
  exercise,
  error,
  task_external = "",
  task_internal = task_external
) {
  task_external <- paste0(if (nzchar(task_external %||% "")) " while ", task_external)
  task_internal <- paste0(if (nzchar(task_internal %||% "")) " while ", task_internal)

  msg_internal <- sprintf(
    "An error occurred%s for exercise '%s'",
    task_internal,
    exercise$label
  )
  rlang::warn(c(msg_internal, "x" = conditionMessage(error)))

  exercise_result(
    list(
      correct = logical(),
      type = "warning",
      location = "replace",
      message = sprintf(
        "An internal error occurred%s. Please try again or contact the tutorial author.",
        task_external
      ),
      error = error
    )
  )
}

exercise_result <- function(
  feedback = NULL,
  html_output = NULL,
  error_message = NULL,
  timeout_exceeded = FALSE
) {
  feedback <- feedback_validated(feedback)

  if (is.character(feedback$html) && any(nzchar(feedback$html))) {
    feedback$html <- htmltools::HTML(feedback$html)
  } else if (!is_html_any(feedback$html)) {
    feedback$html <- feedback_as_html(feedback)
  }

  if (is.character(html_output) && any(nzchar(html_output))) {
    html_output <- htmltools::HTML(html_output)
  } else if (length(html_output) == 0) {
    html_output <- NULL
  }

  structure(
    list(
      feedback = feedback,
      error_message = error_message,
      timeout_exceeded = timeout_exceeded,
      html_output = html_output
    ),
    class = "learnr_exercise_result"
  )
}

is_exercise_result <- function(x) {
  inherits(x, "learnr_exercise_result")
}

is_error_result <- function(x) {
  is_exercise_result(x) && length(x$error_message)
}

# Render Exercise Prep ----------------------------------------------------

is_exercise_engine <- function(exercise, engine) {
  identical(knitr_engine(exercise$engine), knitr_engine(engine))
}

exercise_result_as_html <- function(x) {
  if (!is_exercise_result(x)) {
    return(NULL)
  }

  if (is.null(x$feedback)) {
    return(x$html_output)
  }

  switch(
    x$feedback$location %||% "append",
    append = htmltools::tagList(x$html_output, x$feedback$html),
    prepend = htmltools::tagList(x$feedback$html, x$html_output),
    replace = x$feedback$html,
    stop("Feedback location of ", feedback$location, " not supported")
  )
}

filter_dependencies <- function(dependencies) {
  # purge dependencies that aren't in a package (to close off reading of
  # arbitrary filesystem locations)
  Filter(x = dependencies, function(dependency) {
    if (!is.list(dependency)) {
      FALSE
    } else if (!is.null(dependency$package)) {
      TRUE
    } else {
      ! is.null(tryCatch(
        rprojroot::find_root(rprojroot::is_r_package,
                             path = dependency$src$file),
        error = function(e) NULL
      ))
    }
  })
}

render_exercise_prepare <- function(exercise, ...) {
  UseMethod("render_exercise_prepare", exercise)
}

#' @export
render_exercise_prepare.default <- function(exercise, ...) {
  forced_opts_exercise <- list(
    tutorial = NULL,
    engine = NULL,
    eval = TRUE,
    echo = FALSE,
    cache = FALSE,
    child = NULL,
    indent = NULL,
    dev = "png",
    dpi = 92
  )

  exercise[["opts_chunk"]] <- merge_chunk_options(
    inherited = exercise[["options"]],
    forced = forced_opts_exercise
  )

  discard_forced_opts <- function(opts) {
    opts[setdiff(names(opts), names(forced_opts_exercise))]
  }

  exercise$chunks <- lapply(exercise[["chunks"]], function(chunk) {

    if (identical(chunk[["label"]], exercise[["label"]])) {
      # Exercise Chunk ----
      chunk[["opts"]] <- discard_forced_opts(chunk[["opts"]])

      chunk[["opts"]] <- merge_chunk_options(
        chunk = chunk[["opts"]],
        inherited = I(exercise[["opts_chunk"]])
      )
      # keep only unique options that we over-rode when prepping specific ex type (e.g. sql)
      different_ex_opt <- function(opt, name) !identical(opt, exercise[["opts_chunk"]][[name]])
      chunk[["opts"]] <- chunk[["opts"]][imap_lgl(chunk[["opts"]], different_ex_opt)]
      # move user submission code into the exercise chunk
      chunk[["code"]] <- exercise[["code"]]
    } else {
      # Setup Chunk ----
      chunk[["opts"]] <- merge_chunk_options(
        chunk = chunk[["opts"]],
        forced = list(include = FALSE, tutorial = NULL)
      )
    }
    chunk
  })

  # Restore opts_chunk to R list since merge_chunk_options() dputs the values
  # These chunk options will be used as global knitr chunk options
  exercise[["opts_chunk"]] <- lapply(
    exercise[["opts_chunk"]],
    function(opt) eval(parse(text = opt))
  )
  exercise[["opts_chunk"]] <- compact(exercise[["opts_chunk"]])

  exercise
}

#' @export
render_exercise_prepare.sql <- function(exercise, ...) {
  # Disable invisible warning (that's how sql chunks work)
  exercise[["options"]][["exercise.warn_invisible"]] <- FALSE

  # Set `output.var` so we can find it later, overwriting user name.
  # After rendering, we'll remove the object or reassign it to the `output.var`
  # the author was expecting. (This is much easier than dealing with knitr
  # chunk options in various stages of evaluations/escaping.)
  exercise[["chunks"]] <- lapply(exercise[["chunks"]], function(chunk) {
    if (!identical(chunk[["label"]], exercise[["label"]])) {
      return(chunk)
    }
    chunk[["opts"]][["output.var"]] <- "\"___sql_result\""
    chunk
  })

  NextMethod()
}

#' @export
render_exercise_prepare.python <- function(exercise, ...) {
  rlang::check_installed("reticulate", "for Python exercises")

  NextMethod()
}

# `chunk` are options that user supplied in Rmd (assumed to be strings)
# `inherited` are exercise options
# `forced` are list of manually set options, e.g. list(include=FALSE) for setup chunks.
merge_chunk_options <- function(
  chunk = list(),
  inherited = list(),
  forced = list()
) {
  # note: we quote each option's value if its type is a character, else return as is
  # to prevent rmd render problems (for e.g. fig.keep="high" instead of fig.keep=high)
  if (!is_AsIs(forced)) {
    forced <- lapply(forced, dput_to_string)
  }
  if (!is_AsIs(inherited)) {
    inherited <- lapply(inherited, dput_to_string)
  }
  # get all the unique names of the options
  option_names <- unique(c(names(chunk), names(inherited), names(forced)))
  opts <- lapply(option_names, function(option_name) {
    # first we want manually set options, then user's, then exercise
    forced[[option_name]]  %||%
      chunk[[option_name]] %||%
      inherited[[option_name]]
  })
  # since we manually grab the names, set the names to opts
  names(opts) <- option_names
  # filter out options that already appear in the chunk item
  opts <- opts[!(names(opts) %in% c("label", "engine", "code"))]
  opts[!grepl("^exercise", names(opts))]
}

local_restore_options_and_envvars <- function(.local_envir = parent.frame()) {
  local_restore_options(.local_envir)
  local_restore_envvars(.local_envir)
}

# Render Exercise RMD -----------------------------------------------------
# — Prep ----
render_exercise_rmd_prep <- function(exercise, ...) {
  UseMethod("render_exercise_rmd_prep", exercise)
}

#' @export
render_exercise_rmd_prep.default <- function(exercise, ...) {
  exercise_code_chunks_prep(exercise)
}

# — User ----
render_exercise_rmd_user <- function(exercise, ...) {
  UseMethod("render_exercise_rmd_user", exercise)
}

#' @export
render_exercise_rmd_user.default <- function(exercise, ...) {
  c(
    readLines(system.file("internals", "templates", "exercise-setup.Rmd", package = "learnr")),
    "",
    exercise_code_chunks_user(exercise)
  )
}

#' @export
render_exercise_rmd_user.sql <- function(exercise, ...) {
  rmd_src_user <- NextMethod()

  c(
    rmd_src_user,
    "",
    # knitr's sql chunk engine will either display the results or return the
    # results back to R. We want both, so we ask knitr to return the result and
    # then we explicitly print it in the chunk below.
    '```{r eval=exists("___sql_result")}',
    'get("___sql_result")',
    "```"
  )
}

#' @export
render_exercise_rmd_user.python <- function(exercise, ...) {
  rmd_src_user <- NextMethod()

  c(
    rmd_src_user,
    "",
    # this is how we get the `last_value` from the python session
    '```{r include=FALSE}',
    'reticulate::py_run_string("import builtins")',
    'reticulate::py_eval("builtins._", convert=FALSE)',
    "```"
  )
}

# Render Exercise Stage Hook ----------------------------------------------

# This generic is called AFTER rendering the exercise at the "prep" and "user"
# stages. At the "prep" stage it receives the `envir_prep`, the environment
# after evaluating the setup chunks. At the "user" stage it receives
# `envir_result`, the environment after rendering the user's code.
render_exercise_post_stage_hook <- function(exercise, stage, envir, ...) {
  UseMethod("render_exercise_post_stage_hook", exercise)
}

#' @export
render_exercise_post_stage_hook.default <- function(exercise, ...) {
  invisible()
}


# Render Exercise Duplicate Env -------------------------------------------

# This generic duplicates an environment, generally to take `envir_prep` and
# provide a new environment to be used for `envir_result`.
render_exercise_duplicate_env <- function(exercise, envir, ...) {
  UseMethod("render_exercise_duplicate_env", exercise)
}

#' @export
render_exercise_duplicate_env.default <- function(exercise, envir, ...) {
  duplicate_env(envir)
}

#' @export
render_exercise_duplicate_env.python <- function(exercise, envir, ...) {
  envir <- NextMethod()
  # Add copy of python environment into the prep/restult environment
  assign(".__py__", duplicate_py_env(py_global_env()), envir = envir)
  envir
}

# Render Exercise Result --------------------------------------------------

render_exercise_result <- function(
  exercise,
  ...,
  envir_render,
  envir_prep,
  envir_result,
  evaluate_result,
  last_value,
  html_output
) {
  UseMethod("render_exercise_result", exercise)
}

#' @export
render_exercise_result.default <- function(
  exercise,
  envir_prep,
  envir_result,
  evaluate_result,
  last_value,
  html_output,
  ...
) {
  list(
    evaluate_result = evaluate_result,
    last_value = last_value,
    html_output = html_output,
    envir_result = envir_result,
    envir_prep = envir_prep
  )
}

#' @export
render_exercise_result.sql <- function(
  exercise,
  envir_render,
  envir_prep,
  envir_result,
  last_value,
  ...
) {
  # make sql result available as the last value from the exercise
  if (exists("___sql_result", envir = envir_result)) {
    if (!is.null(exercise[["options"]][["output.var"]])) {
      # the author expected the sql results in a specific variable
      assign(exercise[["options"]][["output.var"]], last_value, envir = envir_result)
    }
    rm("___sql_result", envir = envir_result)
  }

  # make the connection object available in envir_prep (used by gradethis)
  con_name <- exercise[["opts_chunk"]][["connection"]]
  con <- get0(con_name, envir = envir_render, ifnotfound = NULL)
  if (!is.null(con) && isS4(con) && inherits(con, "DBIConnection")) {
    assign(con_name, con, envir = envir_prep)
  }

  # we've only modified environments, so we can return the default method
  NextMethod()
}

#' @export
render_exercise_result.python <- function(exercise, ...) {
  # scrub `evaluate_result` for python exercises
  NextMethod(evaluate_result = NULL)
}


# Exercise Eval Environment Helpers ---------------------------------------

with_masked_env_vars <- function(code, env_vars = list(), opts = list()) {
  # Always disable connect api keys and connect server info
  env_vars$CONNECT_API_KEY <- ""
  env_vars$CONNECT_SERVER <- ""
  env_vars$LEARNR_EXERCISE_USER_CODE <- "TRUE"
  # Hide shiny server sharedSecret
  opts$shiny.sharedSecret <- ""

  # Mask tutorial cache for user code evaluation
  cache_current <- tutorial_cache_env$objects
  tutorial_cache_env$objects <- NULL
  withr::defer(tutorial_cache_env$objects <- cache_current)

  # Disable shiny domain
  shiny::withReactiveDomain(NULL, {
    withr::with_envvar(env_vars, {
      withr::with_options(opts, code)
    })
  })
}

local_restore_options <- function(.local_envir = parent.frame()) {
  opts <- options()
  withr::defer(restore_options(opts), envir = .local_envir)
}

local_restore_envvars <- function(.local_envir = parent.frame()) {
  envvars <- Sys.getenv()
  withr::defer(restore_envvars(envvars), envir = .local_envir)
}

restore_options <- function(old) {
  current    <- options()
  nulls      <- setdiff(names(current), names(old))
  old[nulls] <- list(NULL)
  options(old)
}

restore_envvars <- function(old) {
  current <- Sys.getenv()
  nulls   <- setdiff(names(current), names(old))
  Sys.unsetenv(nulls)
  do.call(Sys.setenv, as.list(old))
}

# Print Methods -----------------------------------------------------------

#' @export
format.tutorial_exercise <- function (x, ..., setup_chunk_only = FALSE) {
  label <- x$label
  if (!isTRUE(setup_chunk_only)) {
    for (chunk in c("solution", "code_check", "check", "error_check", "tests")) {
      if (is.null(x[[chunk]]) || !nzchar(x[[chunk]])) next
      support_chunk <- mock_chunk(
        label = paste0(label, "-", sub("_", "-", chunk)),
        code = x[[chunk]],
        engine = if (chunk == "solution") x$engine
      )
      x$chunks <- c(x$chunks, list(support_chunk))
    }
  }
  chunks <- exercise_code_chunks(x$chunks)
  paste(chunks, collapse = "\n\n")
}

#' @export
print.tutorial_exercise <- function(x, ...) {
  cat(format(x, ...))
}
