
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

    # short circult for restore (we restore some outputs like errors so that
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
      if (!is_windows() && !is_macos())
        evaluator_factory <- forked_evaluator
      else
        evaluator_factory <- inline_evaluator
    }

    # create a new environment parented by the global environment
    # transfer all of the objects in the server_envir (i.e. setup and data chunks)
    envir <- duplicate_env(server_envir, parent = globalenv())

    # create exercise evaluator
    evaluator <- evaluator_factory(evaluate_exercise(exercise, envir), timelimit)

    # start it
    evaluator$start()

    # poll for completion
    o <- observe({

      if (evaluator$completed()) {

        # get the result
        result <- evaluator$result()

        # side-effect: fire event
        exercise_submission_event(
          session = session,
          label = exercise$label,
          code = exercise$code,
          output = result$html_output,
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

# evaluate an exercise and return a list containing output and dependencies
evaluate_exercise <- function(exercise, envir) {

  # capture a copy of the envir before any execution is done
  envir_prep <- duplicate_env(envir)

  # see if we need to do code checking
  if (!is.null(exercise$code_check) && !is.null(exercise$options$exercise.checker)) {

    # get the checker
    checker <- eval(parse(text = exercise$options$exercise.checker), envir = envir)

    # call the checker
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

    # if it's an 'incorrect' feedback result then return it
    if (is.list(checker_feedback)) {
      feedback_validated(checker_feedback)
      if (!checker_feedback$correct) {
        return(list(
          feedback = checker_feedback,
          error_message = NULL,
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

  # hack the pager function so that we can print help
  # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
  pager <- function(files, header, title, delete.file) {
    all.str <- do.call("c",lapply(files,readLines))
    cat(all.str,sep="\n")
  }
  orig_width <- options(width=70)
  on.exit(options(orig_width), add = TRUE)
  orig_pager <- options(pager=pager)
  on.exit(options(orig_pager), add = TRUE)

  # restore knitr options and hooks after knit
  optk <- knitr::opts_knit$get()
  on.exit(knitr::opts_knit$restore(optk), add = TRUE)
  optc <- knitr::opts_chunk$get()
  on.exit(knitr::opts_chunk$restore(optc), add = TRUE)
  hooks <- knitr::knit_hooks$get()
  on.exit(knitr::knit_hooks$restore(hooks), add = TRUE)
  ohooks <- knitr::opts_hooks$get()
  on.exit(knitr::opts_hooks$restore(ohooks), add = TRUE)
  templates <- knitr::opts_template$get()
  on.exit(knitr::opts_template$restore(templates), add = TRUE)

  # set preserved chunk options
  knitr::opts_chunk$set(as.list(exercise$options))

  # temporarily set knitr options (will be rest by on.exit handlers above)
  knitr::opts_chunk$set(echo = FALSE)
  knitr::opts_chunk$set(comment = NA)
  knitr::opts_chunk$set(error = FALSE)

  # write the R code to a temp file (inclue setup code if necessary)
  code <- c(exercise$setup, exercise$code)
  exercise_r <- "exercise.R"
  writeLines(code, con = exercise_r, useBytes = TRUE)

  # spin it to an Rmd
  exercise_rmd <- knitr::spin(hair = exercise_r,
                              knit = FALSE,
                              envir = envir,
                              format = "Rmd")

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
  default_output_handler <- evaluate::new_output_handler()
  has_visible <- length(formals(default_output_handler$value)) > 1
  learnr_output_handler <- evaluate::new_output_handler(value = function(result, visible) {
    last_value <<- last_value

    if (has_visible) {
      default_output_handler$value(x, visible)
    } else {
      if (visible) {
        default_output_handler$value(x)
      } else {
        NULL
      }
    }
  })

  evaluate_result <- NULL
  knitr_options$knit_hooks$evaluate = function(
    code, envir, ...,
    output_handler # set to avoid name collision
  ) {
    evaluate_result <<- evaluate::evaluate(
      code, envir, ...,
      output_handler = learnr_output_handler
    )
    evaluate_result
  }
  output_format <- rmarkdown::output_format(
    knitr = knitr_options,
    pandoc = NULL,
    base_format = rmarkdown::html_fragment(
                    df_print = exercise$options$exercise.df_print,
                    pandoc_args = c("--metadata", "pagetitle=PREVIEW")
                  )
  )

  # knit the Rmd to markdown (catch and report errors)
  error_message <- NULL
  error_html <- NULL
  tryCatch({
    output_file <- rmarkdown::render(input = exercise_rmd,
                                     output_format = output_format,
                                     envir = envir,
                                     clean = FALSE,
                                     quiet = TRUE,
                                     run_pandoc = FALSE)
  }, error = function(e) {
    # make the time limit error message a bit more friendly
    error_message <<- e$message
    pattern <- gettext("reached elapsed time limit", domain="R")
    if (regexpr(pattern, error_message) != -1L) {
      error_message <<- timeout_error_message()
    }
  })
  if (!is.null(error_message))
    return(error_result(error_message))

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

  # get the exercise checker (default does nothing)
  checker <- eval(parse(text = knitr::opts_chunk$get("exercise.checker")),
                  envir = envir)
  if (is.null(exercise$check) || is.null(checker))
    checker <- function(...) { NULL }

  # call the checker
  checker_feedback <- checker(
    label = exercise$label,
    user_code = exercise$code,
    solution_code = exercise$solution,
    check_code = exercise$check,
    envir_result = envir,
    evaluate_result = evaluate_result,
    envir_prep = envir_prep,
    last_value = last_value
  )

  # validate the feedback
  feedback_validated(checker_feedback)

  # amend output with feedback as required
  if (!is.null(checker_feedback)) {
    feedback_html <- feedback_as_html(checker_feedback)
    if (checker_feedback$location == "append")
      html_output <- htmltools::tagList(html_output, feedback_html)
    else if (checker_feedback$location == "prepend")
      html_output <- htmltools::tagList(feedback_html, html_output)
    else if (checker_feedback$location == "replace")
      html_output <- feedback_html
  }

  # return a list with the various results of the expression
  list(
    feedback = checker_feedback,
    error_message = NULL,
    html_output = html_output
  )
}

error_result <- function(error_message) {
  list(
    feedback = NULL,
    error_message = error_message,
    html_output = error_message_html(error_message)
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
