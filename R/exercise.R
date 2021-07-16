current_exercise_version <- "3"

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
    exercise$tutorial <- list(
      tutorial_id = read_request(session, "tutorial.tutorial_id"),
      tutorial_version = read_request(session, "tutorial.tutorial_version"),
      user_id = read_request(session, "tutorial.user_id"),
      learnr_version = as.character(utils::packageVersion("learnr")),
      language = read_request(session, "tutorial.language")
    )

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
      } else if (!is_windows() && !is_macos())
        evaluator_factory <- forked_evaluator_factory
      else
        evaluator_factory <- inline_evaluator
    }

    # supplement the exercise with the global setup options
    # TODO: warn if falling back to the `setup` chunk with an out-of-process evaluator.
    exercise$global_setup <- get_global_setup()
    # retrieve exercise cache information:
    # - chunks (setup + exercise) for the exercise to be processed in `evaluate_exercise`
    # - checker code (check, code-check, error-check)
    # - solution
    # - engine
    exercise <- append(exercise, get_exercise_cache(exercise$label))
    # If there is no locally defined error check code, look for globally defined error check option
    exercise$error_check <- exercise$error_check %||% exercise$options$exercise.error.check.code

    if (!isTRUE(exercise$should_check)) {
      exercise$check <- NULL
      exercise$code_check <- NULL
      exercise$error_check <- NULL
    }
    # variable has now served its purpose so remove it
    exercise$should_check <- NULL

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
            checked          = !is.null(exercise$code_check) || !is.null(exercise$check),
            feedback         = result$feedback
          )
        )

        # assign reactive result value
        rv$triggered <- isolate({ rv$triggered + 1})
        rv$result <- exercise_result_as_html(result)

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

# This function exists to synchronize versions of the exercise objects in case
# an exercise created with an older version of {learnr} is evaluated by a
# newer version of {learnr}. This may be the case when there is a version
# mismatch between the version used to serve the tutorial and the version used
# to evaluate the exercise (external evaluator).
upgrade_exercise <- function(exercise, require_items = NULL) {
  if (identical(exercise$version, current_exercise_version)) {
    return(exercise)
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

  # Future logic to upgrade an exercise from version 3 to version N goes here...

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
  if (inherits(code, "AsIs")) {
    return(code)
  }
  if (is.null(code) || !length(code)) {
    return("")
  }
  str_trim(paste0(code, collapse = "\n"))
}

standardize_exercise_code <- function(exercise) {
  ex_code_items <- c("error_check", "code_check", "check", "code", "global_setup")
  exercise[ex_code_items] <- lapply(exercise[ex_code_items], standardize_code)
  exercise
}

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
  # Protect global options and environment vars from permanent modification
  local_restore_options_and_envvars()

  # adjust exercise version to match the current learnr version
  exercise <- upgrade_exercise(
    exercise,
    require_items = if (evaluate_global_setup) "global_setup"
  )

  # standardize exercise code to single string (code, *check, global_setup)
  exercise <- standardize_exercise_code(exercise)

  i18n_set_language_option(exercise$tutorial$language)

  # return immediately and clear visible results
  # do not consider this an exercise submission
  if (!nzchar(exercise$code)) {
    # " " since html_output needs to pass a req()
    return(exercise_result(html_output = " "))
  }

  if (evaluate_global_setup) {
    eval(parse(text = exercise$global_setup), envir = envir)
  }

  # Check if user code has unfilled blanks; if it does, early return
  exercise_blanks <- exercise$options$exercise.blanks %||%
    knitr::opts_chunk$get("exercise.blanks") %||%
    TRUE
  if (isTRUE(exercise_blanks)) exercise_blanks <- "_{3,}"

  blank_feedback <- NULL
  if (shiny::isTruthy(exercise_blanks)) {
    blank_feedback <- check_blanks(exercise$code, exercise_blanks)
  }

  return_if_exercise_result <- function(res) {
    # early return if the we've received an exercise result,
    # but also replace the feedback with the blank feedback if any were found
    if (!is_exercise_result(res)) {
      return(NULL)
    }

    if (!is.null(blank_feedback$feedback)) {
      res$feedback <- blank_feedback$feedback
    }

    rlang::return_from(rlang::caller_env(), res)
  }


  # Check if user code is parsable; if not, early return
  if (
    tolower(exercise$engine) == "r" &&
    !isFALSE(exercise$options$exercise.parse.check)
  ) {
    return_if_exercise_result(check_parsable(exercise$code))
  }

  # Check the code pre-evaluation, if code_check is provided
  if (nzchar(exercise$code_check)) {
    # treat the blank check like a code check, if blanks were detected
    return_if_exercise_result(blank_feedback)

    return_if_exercise_result(
      try_checker(
        exercise,
        check_code = exercise$code_check,
        envir_prep = duplicate_env(envir)
      )
    )
  }

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
      error_feedback <- NULL
      if (nzchar(exercise$error_check)) {
        # Check the error thrown by the submitted code when there's error
        # checking: the exercise could be to throw an error!
        error_feedback <- try_checker(
          exercise,
          check_code = exercise$error_check,
          envir_result = err_render$envir_result,
          evaluate_result = err_render$evaluate_result,
          envir_prep = err_render$envir_prep,
          last_value = err_render
        )
      }
      exercise_result_error(err_render$error_message, error_feedback$feedback)
    }
  )

  return_if_exercise_result(rmd_results)

  # Run the checker post-evaluation (for checking code results)
  # Don't need to do exercise checking if there are blanks
  checker_feedback <- NULL
  if (is.null(blank_feedback) && nzchar(exercise$check)) {
    checker_feedback <- try_checker(
      exercise,
      check_code = exercise$check,
      envir_result = rmd_results$envir_result,
      evaluate_result = rmd_results$evaluate_result,
      envir_prep = rmd_results$envir_prep,
      last_value = rmd_results$last_value
    )
  }

  # Return checker feedback (if any) with the exercise results
  exercise_result(
    feedback = checker_feedback$feedback %||% blank_feedback$feedback,
    html_output = rmd_results$html_output
  )
}


try_checker <- function(
  exercise, name = "exercise.checker", check_code = NULL, envir_result = NULL,
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
    engine = engine
  )
  # Throw better error messaging if the checker function signature is ill-defined
  missing_args <- setdiff(names(args), checker_args)
  if (length(missing_args) && !"..." %in% checker_args) {
    msg <- sprintf(
      "Either add ... or the following arguments to the '%s' function: '%s'",
      name, paste(missing_args, collapse = "', '")
    )
    message(msg)
    rlang::return_from(rlang::caller_env(), exercise_result_error(msg))
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

render_exercise <- function(exercise, envir) {
  # Protect global options and environment vars from modification by student
  local_restore_options_and_envvars()

  # Make sure exercise (& setup) chunk options and code are prepped for rendering
  exercise <- prepare_exercise(exercise)

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
    knitr_options <- exercise$options
    # Recreate the logic of `rmarkdown::knitr_options_html()` by setting these options
    knitr_options$opts_chunk$dev <- "png"
    knitr_options$opts_chunk$dpi <- 96

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

  # Prepare code chunks containing exercise prep (setup) and user code
  rmd_src_prep <- exercise_code_chunks_prep(exercise)
  rmd_src_user <- c(
    readLines(system.file("internals", "templates", "exercise-setup.Rmd", package = "learnr")),
    "", exercise_code_chunks_user(exercise)
  )

  envir_prep <- duplicate_env(envir)
  # placeholder envir_result in case an error occurs with setup chunks
  envir_result <- envir_prep

  # First, Rmd to markdown (and exit early if any error)
  output_file <- tryCatch({
    local({
      if (length(rmd_src_prep) > 0) {
        rmd_file_prep <- "exercise_prep.Rmd"
        writeLines(rmd_src_prep, con = rmd_file_prep, useBytes = TRUE)
        on.exit(unlink(dir(pattern = "exercise_prep")), add = TRUE)

        # First pass without user code to get envir_prep
        rmd_file_prep_html <- rmarkdown::render(
          input = rmd_file_prep,
          output_format = output_format_exercise(user = FALSE),
          envir = envir_prep,
          clean = TRUE,
          quiet = TRUE,
          run_pandoc = FALSE
        )
      }
    })

    # Create exercise.Rmd after running setup so it isn't accidentally overwritten
    if (file.exists("exercise.Rmd")) {
      warning(
        "Evaluating user code in exercise '", exercise$label, "' created ",
        "'exercise.Rmd'. If the setup code for this exercise creates a file ",
        "with that name, please choose another name.",
        immediate. = TRUE
      )
    }
    rmd_file_user <- "exercise.Rmd"
    writeLines(rmd_src_user, con = rmd_file_user, useBytes = TRUE)

    # Copy in a full clone `envir_prep` before running user code in `envir_result`
    # By being a sibling to `envir_prep` (rather than a dependency),
    # alterations to `envir_prep` from eval'ing code in `envir_result`
    # are much more difficult
    envir_result <- duplicate_env(envir_prep)

    # Now render user code for final result
    rmarkdown::render(
      input = rmd_file_user,
      output_format = output_format_exercise(user = TRUE),
      envir = envir_result,
      clean = FALSE,
      quiet = TRUE,
      run_pandoc = FALSE
    )
  }, error = function(e) {
    msg <- conditionMessage(e)
    # make the time limit error message a bit more friendly
    pattern <- gettext("reached elapsed time limit", domain = "R")
    if (grepl(pattern, msg, fixed = TRUE)) {
      return(exercise_result_timeout())
    }
    rlang::abort(
      class = "learnr_render_exercise_error",
      envir_result = envir_result,
      evaluate_result = evaluate_result,
      envir_prep = envir_prep,
      last_value = e,
      error_message = msg
    )
  })

  if (is_exercise_result(output_file)) {
    # this only happens when the render result is a timeout error
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

  list(
    evaluate_result = evaluate_result,
    last_value = last_value,
    html_output = html_output,
    envir_result = envir_result,
    envir_prep = envir_prep
  )
}

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
  # chunk options on the user chunk just duplicate the exercise$options
  # which are set globally for the exercise
  user_chunk <- exercise_get_chunks(exercise, "user")
  user_chunk[[1]]$opts <- NULL
  exercise_code_chunks(user_chunk)
}

exercise_code_chunks <- function(chunks) {
  vapply(chunks, function(x) {
    opts <- paste(names(x$opts), unname(x$opts), sep = "=")
    paste(
      sep = "\n",
      # we quote the label to ensure that it is treated as a label and not a symbol for instance
      sprintf("```{%s}", paste0(c(x$engine, dput_to_string(x$label), opts), collapse = ", ")),
      paste0(x$code, collapse = "\n"),
      "```"
    )
  }, character(1))
}

check_blanks <- function(user_code, blank_regex) {
  blank_regex <- paste(blank_regex, collapse = "|")

  blanks <- str_match_all(user_code, blank_regex)

  if (!length(blanks)) {
    return(NULL)
  }

  msg <- paste(
    i18n_span(
      "text.exercisecontainsblank", opts = list(count = length(blanks))
    ),
    i18n_span(
      "text.pleasereplaceblank",
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

check_parsable <- function(user_code) {
  error <- rlang::catch_cnd(parse(text = user_code), "error")
  if (is.null(error)) {
    return(NULL)
  }

  exercise_result(
    list(
      message = HTML(i18n_span("text.unparsable")),
      correct = FALSE,
      location = "append",
      type = "error"
    ),
    html_output = error_message_html(error$message),
    error_message = error$message
  )
}

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

exercise_result <- function(feedback = NULL, html_output = NULL,
                            error_message = NULL, timeout_exceeded = FALSE) {
  feedback <- feedback_validated(feedback)

  if (!is.null(feedback)) {
    feedback$html <- feedback_as_html(feedback)
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


prepare_exercise <- function(exercise) {
  exercise$chunks <- lapply(exercise$chunks, function(chunk) {
    isExercise <- identical(chunk$label, exercise$label)
    chunk$opts <- merge_options(
      preserved_opts = chunk$opts,
      # don't include the exercise options in setup chunks
      inherited_opts = if (isExercise) exercise$options else list(),
      static_opts = if (isExercise) {
        list(
          eval = TRUE, echo = FALSE, tutorial = NULL,
          cache = FALSE, child = NULL
        )
      } else {
        # don't include results in setup chunks
        list(include = FALSE)
      }
    )
    # Move over user submission code to the pre-rendered chunk object
    if (isExercise) {
      chunk$code <- exercise$code
    }
    chunk
  })
  exercise
}

# `preserved_opts` are options that user supplied in Rmd
# `inherited_opts` are exercise options
# `static_opts` are list of manually set options, e.g. list(include=FALSE) for setup chunks.
merge_options <- function(preserved_opts, inherited_opts, static_opts = list()) {
  # note: we quote each option's value if its type is a character, else return as is
  # to prevent rmd render problems (for e.g. fig.keep="high" instead of fig.keep=high)
  static_opts <- lapply(static_opts, dput_to_string)
  inherited_opts <- lapply(inherited_opts, dput_to_string)
  # get all the unique names of the options
  option_names <- unique(c(names(preserved_opts), names(inherited_opts), names(static_opts)))
  opts <- lapply(option_names, function(option_name) {
    # first we want manually set options, then user's, then exercise
    static_opts[[option_name]]  %||%
      preserved_opts[[option_name]] %||%
      inherited_opts[[option_name]]
  })
  # since we manually grab the names, set the names to opts
  names(opts) <- option_names
  # filter out options we don't need for the exercise.Rmd
  opts <- opts[!(names(opts) %in% c("label", "engine", "code"))]
  opts[!grepl("^exercise", names(opts))]
}

local_restore_options_and_envvars <- function(.local_envir = parent.frame()) {
  local_restore_options(.local_envir)
  local_restore_envvars(.local_envir)
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

#' An Exercise Checker for Debugging
#'
#' An exercise checker for debugging that renders all of the expected arguments
#' of the `exercise.checker` option into HTML. Additionally, this function is
#' used in testing  of `evaluate_exercise()`.
#'
#' @param label Exercise label
#' @param user_code Submitted user code
#' @param solution_code The code in the `*-solution` chunk
#' @param check_code The checking code that originates from the `*-check` chunk,
#'   the `*-code-check` chunk, or the `*-error-check` chunk.
#' @param envir_prep,envir_result The environment before running user code
#'   (`envir_prep`) and the environment just after running the user's code
#'   (`envir_result`).
#' @param evaluate_result The return value from `evaluate::evaluate()`, called
#'   on `user_code`
#' @param last_value The last value after evaluating `user_code`
#' @param engine The engine of the exercise chunk
#' @param ... Not used (future compatibility)
#'
#' @keywords internal
debug_exercise_checker <- function(
  label,
  user_code,
  solution_code,
  check_code,
  envir_result,
  evaluate_result,
  envir_prep,
  last_value,
  engine,
  ...
) {
  # Use I() around check_code to indicate that we want to evaluate the check code
  checker_result <- if (inherits(check_code, "AsIs")) {
    local(eval(parse(text = check_code)))
  }

  tags <- htmltools::tags
  collapse <- function(...) paste(..., collapse = "\n")

  str_chr <- function(x) {
    utils::capture.output(utils::str(x))
  }

  str_env <- function(env) {
    if (is.null(env)) {
      return("NO ENVIRONMENT")
    }
    vars <- ls(env)
    names(vars) <- vars
    x <- str_chr(lapply(vars, function(v) get(v, env)))
    x[-1]
  }

  code_block <- function(value, engine = "r") {
    tags$pre(
      class = engine,
      tags$code(collapse(value), .noWS = "inside"),
      .noWS = "inside"
    )
  }

  message <- htmltools::tagList(
    tags$p(
      tags$strong("Exercise label:"),
      tags$code(label),
      tags$br(),
      tags$strong("Engine:"),
      tags$code(engine)
    ),
    tags$p(
      "last_value",
      code_block(last_value)
    ),
    tags$details(
      tags$summary("envir_prep"),
      code_block(str_env(envir_prep))
    ),
    tags$details(
      tags$summary("envir_result"),
      code_block(str_env(envir_result))
    ),
    tags$details(
      tags$summary("user_code"),
      code_block(user_code, engine)
    ),
    tags$details(
      tags$summary("solution_code"),
      code_block(solution_code)
    ),
    tags$details(
      tags$summary("check_code"),
      code_block(check_code)
    ),
    tags$details(
      tags$summary("evaluate_result"),
      code_block(str_chr(evaluate_result))
    )
  )

  list(
    message = message,
    correct = logical(),
    type = "custom",
    location = "replace",
    checker_result = checker_result,
    checker_args = list(
      label           = label,
      user_code       = user_code,
      solution_code   = solution_code,
      check_code      = check_code,
      envir_result    = envir_result,
      evaluate_result = evaluate_result,
      envir_prep      = envir_prep,
      last_value      = last_value,
      engine          = engine,
      "..."           = list(...)
    )
  )
}
