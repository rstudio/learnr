
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

    # get exercise
    exercise <- exercise_rx()

    # short circuit for restore (we restore some outputs like errors so that
    # they are not re-executed when bringing the tutorial back up)
    if (exercise$restore) {
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

    # get timelimit option (either from chunk option or from global option)
    timelimit <- exercise$options$exercise.timelimit
    if (is.null(timelimit))
      timelimit <- getOption("tutorial.exercise.timelimit", default = 30)

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
    # - checker code (check, code-check)
    # - solution
    # - engine
    exercise <- append(exercise, get_exercise_cache(exercise$label))
    if (!isTRUE(exercise$should_check)) {
      exercise$check <- NULL
      exercise$code_check <- NULL
    }
    # variable has now served its purpose so remove it
    exercise$should_check <- NULL

    # placeholder for current learnr version to deal with exercise structure differences
    # with other learnr versions
    exercise$version <- "1"

    # create a new environment parented by the global environment
    # transfer all of the objects in the server_envir (i.e. setup and data chunks)
    envir <- duplicate_env(server_envir, parent = globalenv())

    # create exercise evaluator
    evaluator <- evaluator_factory(evaluate_exercise(exercise, envir),
                                   timelimit, exercise, session)

    # Create exercise ID to map the associated events.
    ex_id <- random_id("lnr_ex")

    # fire event before computing
    exercise_submitted_event(
      session = session,
      id = ex_id,
      label = exercise$label,
      code = exercise$code,
      restore = exercise$restore
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
        exercise_result_event(
          session = session,
          id = ex_id,
          label = exercise$label,
          code = exercise$code,
          output = result$html_output,
          timeout_exceeded = result$timeout_exceeded,
          time_elapsed = as.numeric(difftime(Sys.time(), start, units="secs")),
          error_message = result$error_message,
          checked = !is.null(exercise$code_check) || !is.null(exercise$check),
          feedback = result$feedback
        )

        # assign reactive result value
        rv$triggered <- isolate({ rv$triggered + 1})
        rv$result <- result$html_output

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

# helper function that will upgrade a previous learnr exercise into new learnr exercise
# TODO: do the actual upgrade
upgrade_exercise <- function(exercise) {
  # if version doesn't exist we're at "0" (older learnr)
  if (is.null(exercise$version)) {
    exercise$version <- "0"
  }
  # for now, raise error when learnr version is not supported
  # else, return the exercise for the correct version, "1"
  switch(exercise$version,
         "0" = stop("Exercise version not supplied! Unable to upgrade exercise."),
         "1" = { exercise },
         stop("Exercise version unknown. Unable to upgrade exercise.")
  )
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
evaluate_exercise <- function(exercise, envir, evaluate_global_setup = FALSE) {

  # for compatibility with previous learnr versions, we'll upgrade exercise (if possible)
  exercise <- upgrade_exercise(exercise)

  # return immediately and clear visible results
  # do not consider this an exercise submission
  if (
    !nzchar(
      str_trim(paste0(exercise$code, collapse = "\n"))
    )
  ) {
    return(empty_result())
  }

  if (evaluate_global_setup) {
    eval(parse(text = exercise$global_setup), envir = envir)
  }

  # capture a copy of the envir before any execution is done
  envir_prep <- duplicate_env(envir)

  # "global" err object to look for
  err <- NULL
  get_checker <- function() {
    checker <- exercise$options$exercise.checker
    if (is.function(checker)) {
      environment(checker) <- envir_prep
    } else if (!is.null(checker)) {
      warning("Found a exercise.checker that isn't a function", call. = FALSE)
      checker <- NULL
    }
    checker
  }

  # get the checker & see if we need to do code checking
  checker <- get_checker()
  if (!is.null(exercise$code_check) && is.function(checker)) {

    # call the checker
    tryCatch({
      checker_feedback <- checker(
        label = exercise$label,
        user_code = exercise$code,
        solution_code = exercise$solution,
        check_code = exercise$code_check,
        envir_result = NULL,
        evaluate_result = NULL,
        envir_prep = envir_prep,
        last_value = NULL
      )
    }, error = function(e) {
      err <<- e$message
      message("Error occured while evaluating initial 'exercise.checker'. Error:\n", e)
    })
    if (!is.null(err)) {
      return(error_result("Error occured while evaluating initial 'exercise.checker'."))
    }

    # if it's an 'incorrect' feedback result then return it
    if (is.list(checker_feedback)) {
      feedback_validated(checker_feedback)
      if (!checker_feedback$correct) {
        return(list(
          feedback = checker_feedback,
          error_message = NULL,
          timeout_exceeded = FALSE,
          html_output = feedback_as_html(checker_feedback)
        ))
      }
    }
  }

  # create temp dir for execution (remove on exit)
  exercise_dir <- tempfile(pattern = "learnr-tutorial-exercise")
  dir.create(exercise_dir)
  oldwd <- setwd(exercise_dir)
  on.exit({
    setwd(oldwd)
    unlink(exercise_dir, recursive = TRUE)
  }, add = TRUE)

  # helper function to return "key=value" character for knitr options
  equal_separate_opts <- function(opts) {
    if (length(opts) == 0) {
      return(NULL)
    }
    paste0(names(opts), "=", unname(opts))
  }

  # helper function that unpacks knitr chunk options and
  # returns a single character vector (e.g. "tidy=TRUE, prompt=FALSE")
  # `preserved_opts` are options that user supplied in Rmd
  # `inherited_opts` are exercise options
  # `static_opts` are list of manually set options, e.g. list(include=FALSE) for setup chunks.
  unpack_options <- function(preserved_opts, inherited_opts, static_opts = list()) {
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
    opts <- opts[!grepl("^exercise", names(opts))]
    equal_separate_opts(opts)
  }

  # construct a global setup chunk to set knitr options
  knitr_setup_header <- "```{r learnr-setup, include=FALSE}"
  # hack the pager function so that we can print help with custom pager function
  # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
  knitr_setup_body <- paste0(
    # the options restoration is done after processing the exercise.Rmd
    c("options(pager=function(files, header, title, delete.file) {
        all.str <- do.call(\"c\",lapply(files,readLines))
        cat(all.str,sep=\"\\n\")
      })",
      "knitr::opts_chunk$set(echo = FALSE)",
      "knitr::opts_chunk$set(comment = NA)",
      "knitr::opts_chunk$set(error = FALSE)"),
    collapse = "\n"
  )
  knitr_setup_footer <- "\n```"
  knitr_setup_rmd <- paste0(c(knitr_setup_header, knitr_setup_body, knitr_setup_footer), collapse = "\n")

  # helper function that processes a list of raw setup chunks and
  # returns a single character vector of knitr chunks for an Rmd file
  get_chunk_rmds <- function(chunks) {
    if (is.null(chunks)) return(NULL)
    setup_rmds <- vapply(chunks, character(1), FUN = function(chunk_info) {
        # construct the knitr Rmd for exercise and its setup chunks
        # handle exercise chunk differently from setup chunks
        if (identical(chunk_info$label, exercise$label)) {
          # grab exercise code
          code <- exercise$code
          # manually set exercise relevant options, disable other options
          static_opts <- list(include = TRUE,
                              eval = TRUE,
                              echo = FALSE,
                              tutorial = NULL,
                              cache = FALSE,
                              child = NULL
          )
          # construct a character of all of the options
          opts <- unpack_options(
            preserved_opts = chunk_info$opts,
            inherited_opts = exercise$options,
            static_opts = static_opts
          )
        } else {
          # grab setup code
          code <- chunk_info$code
          # set `include` to false for setup chunks to prevent printing last value
          static_opts <- list(include = FALSE)
          # for setup chunk, we don't include any exercise options (inherited_opts)
          opts <- unpack_options(
            preserved_opts = chunk_info$opts,
            inherited_opts = list(),
            static_opts = static_opts
          )
        }
        # if there's an engine option it's non-R code
        engine <- chunk_info$engine
        # we quote the label to ensure that it is treated as a label and not a symbol for instance
        label_opts <- paste0(c(engine, dput_to_string(chunk_info$label), opts), collapse = ", ")
        paste(
          paste0("```{", label_opts, "}"),
          paste0(code, collapse = "\n"),
          "```",
          sep = "\n"
        )
      }
    )
    paste0(setup_rmds, sep = "\n")
  }

  # construct the exercise chunks
  exercise_rmds <- get_chunk_rmds(exercise$chunks)
  code <- c(knitr_setup_rmd, exercise_rmds)

  # write the final Rmd to process with `rmarkdown::render` later
  exercise_rmd <- "exercise.Rmd"
  writeLines(code, con = exercise_rmd, useBytes = TRUE)

  # create html_fragment output format with forwarded knitr options
  knitr_options <- rmarkdown::knitr_options_html(
    fig_width = exercise$options$fig.width,
    fig_height = exercise$options$fig.height,
    fig_retina = exercise$options$fig.retina,
    keep_md = FALSE
  )

  # capture the last value and use a regular output handler for value
  # https://github.com/r-lib/evaluate/blob/e81ba2ba181827a86525767371e6dfdeb364c8b7/R/output.r#L54-L56
  # @param value Function to handle the values returned from evaluation. If it
  #   only has one argument, only visible values are handled; if it has more
  #   arguments, the second argument indicates whether the value is visible.
  last_value <- NULL
  last_value_is_visible <- TRUE

  evaluate_result <- NULL
  knitr_options$knit_hooks$evaluate = function(
    code, envir, ...,
    output_handler # knitr's output_handler
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
  output_format <- rmarkdown::output_format(
    knitr = knitr_options,
    pandoc = NULL,
    base_format = rmarkdown::html_fragment(
                    df_print = exercise$options$exercise.df_print,
                    pandoc_args = c("--metadata", "title=PREVIEW")
                  )
  )

  # knit the Rmd to markdown (catch and report errors)
  tryCatch({
    # make sure the exercise did not alter global options
    output_file <- local({
      opts <- options()
      on.exit({ options(opts) }, add = TRUE)
      output_file <- rmarkdown::render(input = exercise_rmd,
                                       output_format = output_format,
                                       envir = envir,
                                       clean = FALSE,
                                       quiet = TRUE,
                                       run_pandoc = FALSE)
    })
  }, error = function(e) {
    # make the time limit error message a bit more friendly
    err <<- e$message
    pattern <- gettext("reached elapsed time limit", domain="R")
    if (regexpr(pattern, err) != -1L) {
      err <<- timeout_error_message()
    }
  })
  if (!is.null(err)) {
    return(error_result(err))
  }

  # capture and filter dependencies
  dependencies <- attr(output_file, "knit_meta")
  dependencies <- filter_dependencies(dependencies)

  # render the markdown
  output_file <- rmarkdown::render(input = output_file,
                                   output_format = output_format,
                                   envir = envir,
                                   quiet = TRUE,
                                   clean = FALSE)
  output <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
  output <- paste(output, collapse = "\n")


  # capture output as HTML w/ dependencies
  html_output <- htmltools::attachDependencies(
    htmltools::HTML(output),
    dependencies
  )

  checker_feedback <- NULL
  if (!is.null(exercise$check) && is.function(checker)) {
    # call the checker
    tryCatch({
      checker_feedback <- checker(
        label = exercise$label,
        user_code = exercise$code,
        solution_code = exercise$solution,
        check_code = exercise$check, # use the cached checker for exercise
        envir_result = envir,
        evaluate_result = evaluate_result,
        envir_prep = envir_prep,
        last_value = last_value
      )
    }, error = function(e) {
      err <<- e$message
      message("Error occured while evaluating 'exercise.checker'. Error:\n", e)
    })
    if (!is.null(err)) {
      return(error_result("Error occured while evaluating 'exercise.checker'."))
    }
  }


  # validate the feedback
  feedback_validated(checker_feedback)

  # amend output with feedback as required
  feedback_html <-
    if (!is.null(checker_feedback)) {
      feedback_as_html(checker_feedback)
    } else {
      NULL
    }

  if (
    # if the last value was invisible
    !last_value_is_visible &&
    # if the checker function exists
    is.function(checker)
  ) {
    # works with NULL feedback
    feedback_html <- htmltools::tagList(feedback_html, invisible_feedback())
  }

  if (!is.null(feedback_html)) {
    # if no feedback, append invisible_feedback
    feedback_location <- checker_feedback$location %||% "append"
    if (feedback_location == "append") {
      html_output <- htmltools::tagList(html_output, feedback_html)
    } else if (feedback_location == "prepend") {
      html_output <- htmltools::tagList(feedback_html, html_output)
    } else if (feedback_location == "replace") {
      html_output <- feedback_html
    }
  }

  # return a list with the various results of the expression
  list(
    feedback = checker_feedback,
    error_message = NULL,
    timeout_exceeded = FALSE,
    html_output = html_output
  )
}

empty_result <- function() {
  list(
    feedback = NULL,
    error_message = NULL,
    timeout_exceeded = FALSE,
    html_output = NULL
  )
}
# @param timeout_exceeded represents whether or not the error was triggered
#   because the exercise exceeded the timeout. Use NA if unknown
error_result <- function(error_message, timeout_exceeded=NA) {
  list(
    feedback = NULL,
    timeout_exceeded = timeout_exceeded,
    error_message = error_message,
    html_output = error_message_html(error_message)
  )
}
invisible_feedback <- function() {
  feedback_as_html(
    feedback_validated(
      list(
        message = "Last value being used to check answer is invisible. See `?invisible` for more information",
        type = "warning",
        correct = FALSE,
        location = "append"
      )
    )
  )
}

timeout_error_message <- function() {
  paste("Error: Your code ran longer than the permitted time",
        "limit for this exercise.")
}


filter_dependencies <- function(dependencies) {
  # purge dependencies that aren't in a package (to close off reading of
  # artibtary filesystem locations)
  Filter(x = dependencies, function(dependency) {
    if (!is.null(dependency$package)) {
      TRUE
    }
    else {
      ! is.null(tryCatch(
        rprojroot::find_root(rprojroot::is_r_package,
                             path = dependency$src$file),
        error = function(e) NULL
      ))
    }
  })
}
