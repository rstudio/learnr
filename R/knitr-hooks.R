detect_installed_knitr_hooks <- function() {
  tutorial_chunk_opt <- knitr::opts_chunk$get("tutorial")
  if (!(isTRUE(tutorial_chunk_opt) || identical(tutorial_chunk_opt, "TRUE"))) {
    return(FALSE)
  }

  tutorial_opts_hook <- knitr::opts_hooks$get("tutorial")
  if (!is.function(tutorial_opts_hook)) {
    return(FALSE)
  }

  tutorial_knit_hook <- knitr::knit_hooks$get("tutorial")
  is.function(tutorial_knit_hook)
}

tutorial_knitr_options <- function() {
  # helper to check for runtime: shiny_prerendered being active
  is_shiny_prerendered_active <- function() {
    identical(knitr::opts_knit$get("rmarkdown.runtime"),"shiny_prerendered")
  }

  # helper to check for an exercise chunk
  is_exercise_chunk <- function(options) {
    isTRUE(options[["exercise"]])
  }

  # helper to find chunks that name a chunk as their setup chunk
  exercise_chunks_for_setup_chunk <- function(label) {
    label_query <- paste0("knitr::all_labels(exercise.setup == '", label, "')")
    eval(parse(text = label_query))
  }

  # helper to check for an exercise support chunk
  is_exercise_support_chunk <- function(options, type = c("setup",
                                                          "hint",
                                                          "hint-\\d+",
                                                          "solution",
                                                          "error-check",
                                                          "code-check",
                                                          "check")) {
    support_regex <- paste0("-(", paste(type, collapse = "|"), ")$")
    if (grepl(support_regex, options$label)) {
      exercise_label <- sub(support_regex, "", options$label)
      label_query <- "knitr::all_labels(exercise == TRUE)"
      all_exercise_labels <- eval(parse(text = label_query))
      exercise_label %in% all_exercise_labels
    }
    else if (identical(options$label, "setup-global-exercise")) {
      TRUE
    }
    else if ("setup" %in% type) {
      # look for another chunk which names this as it's setup chunk or if it has `exercise.setup`
      # this second condition is for support chunks that isn't referenced by an exercise yet
      # but is part of a chain and should be stored as a setup chunk
      is_referenced <- length(exercise_chunks_for_setup_chunk(options$label)) > 0
      if (is_referenced) {
        find_parent_setup_chunks(options) # only used to check for cycles; the return value is not useful here
        TRUE
      } else {
        # if this looks like a setup chunk, but no one references it, error
        if (is.null(options[["exercise"]]) && !is.null(options$exercise.setup)) {
          stop(
            "Chunk '", options$label, "' is not being used by any exercise or exercise setup chunk.\n",
            "Please remove chunk '", options$label, "' or reference '", options$label, "' with `exercise.setup = '", options$label, "'`",
               call. = FALSE)
        }
        # just a random chunk
        FALSE
      }
    }
    else {
      FALSE
    }
  }

  is_exercise_setup_chunk <- function(label) {
    grepl("-setup$", label) || (length(exercise_chunks_for_setup_chunk(label)) > 0)
  }

  # helper function to grab the raw knitr chunk associated with a chunk label
  get_knitr_chunk <- function(label) {
    # Note: we directly call the knitr function in this case because we do not
    # need to pass expressions which required delayed evaluation.
    knitr::knit_code$get(label)
  }

  get_setup_global_exercise <- function() {
    # setup-global-exercise is a special chunk name that will over-ride the
    # global setup chunk, but only for external evaluators. This lets tutorials
    # have separate setup code for the local shiny app and the remote evaluator.
    knitr::knit_code$get("setup-global-exercise") %||%
      knitr::knit_code$get("setup")
  }

  # helper function to find all the setup chunks associated with an exercise chunk
  # it goes up the chain of setup dependencies and returns a list of raw knitr chunks (if any)
  find_parent_setup_chunks <- function(options, visited = NULL) {
    # base case: when options are null, there are no more setup references
    if (is.null(options))
      return(NULL)
    has_visited <- options$label %in% visited
    # update visited set
    visited <- append(visited, options$label)
    # error out if there is a cycle
    if (has_visited) {
      stop("Chained setup chunks form a cycle!\nCycle: ", paste0(visited, collapse = " => "), call. = FALSE)
    }
    # check if the chunk with label has another setup chunk associated with it
    setup_label <- options$exercise.setup
    setup_chunk <- get_knitr_chunk(setup_label)
    # if the setup_label is mispelled, throw an error to user instead of silently ignoring
    # which would cause other issues when data dependencies can't be found
    if (!is.null(setup_label) && is.null(setup_chunk))
      stop(paste0("exercise.setup label '", setup_label, "' not found for exercise '", options$label, "'"))

    setup_options <- attr(setup_chunk, "chunk_opts")
    # serialize the options here so that the values are not evaluated when retrieved from learnr cache
    current_setup_chunks <- if (is.null(setup_options)) {
      list()
    } else {
      list(
        list(
          label = setup_label,
          code = paste0(setup_chunk, collapse = "\n"),
          opts = lapply(setup_options, dput_to_string),
          engine = knitr_engine(setup_options$engine)
        )
      )
    }
    # recurse
    append(find_parent_setup_chunks(setup_options, visited), current_setup_chunks)
  }

  # helper function to return a list of exercise chunk and its setup chunks
  get_all_chunks <- function(options) {
    # get the exercise chunk
    exercise_chunk <- get_knitr_chunk(options$label)
    exercise_options <- attr(exercise_chunk, "chunk_opts")
    # serialize the exercise options here so that the values are not evaluated when retrieved from learnr cache
    chunk_opts <- lapply(exercise_options, dput_to_string)
    exercise_chunk <- paste0(exercise_chunk, collapse = "\n")
    # append the setup chunks at the front
    # retrieve the setup chunks associated with the exercise
    # if there is no `exercise.setup` find one with "label-setup"
    setup_chunks <-
      if (!is.null(options$exercise.setup)) {
        find_parent_setup_chunks(options)
      } else if (!is.null(get_knitr_chunk(paste0(options$label, '-setup')))) {
        options$exercise.setup <- paste0(options$label, '-setup')
        find_parent_setup_chunks(options)
      } else {
        NULL
      }
    append(setup_chunks, list(list(label = options$label, code = exercise_chunk, opts = chunk_opts, engine = knitr_engine(options$engine))))
  }

  get_reveal_solution_option <- function(solution_opts) {
    exercise_chunk <- get_knitr_chunk(sub("-solution$", "", solution_opts$label))
    if (is.null(exercise_chunk)) {
      stop("Can not find exercise chunk for solution: `", solution_opts$label, "`")
    }

    # these are unevaluated options at this point
    exercise_opts <- attr(exercise_chunk, "chunk_opts")
    # get explicit opts on solution chunk since solution_opts was merged
    # with the global knitr chunk options
    sol_opts_user <- attr(get_knitr_chunk(solution_opts$label), "chunk_opts")

    # Determine if we should reveal the solution using...
    reveal_solution <-
      # 1. the option explicitly set on the solution chunk
      eval(sol_opts_user$exercise.reveal_solution, envir = knitr::knit_global()) %||%
      # 2. the option explicitly set on the exercise chunk
      eval(exercise_opts$exercise.reveal_solution, envir = knitr::knit_global()) %||%
      # 3. the global knitr chunk option
      solution_opts$exercise.reveal_solution %||%
      # 4. the global R option
      getOption("tutorial.exercise.reveal_solution", TRUE)

    isTRUE(reveal_solution)
  }

  # hook to turn off evaluation/highlighting for exercise related chunks
  tutorial_opts_hook <-  function(options) {

    # check for chunk type
    exercise_chunk <- is_exercise_chunk(options)
    exercise_support_chunk <- is_exercise_support_chunk(options)
    exercise_setup_chunk <- is_exercise_support_chunk(options, type = "setup")

    # validate that we have runtime: shiny_prerendered
    if ((exercise_chunk || exercise_support_chunk) && !is_shiny_prerendered_active()) {
      stop("Tutorial exercises require the use of 'runtime: shiny_prerendered'",
           call. = FALSE)
    }

    # validate that the exercise chunk is 'defined'
    if (exercise_chunk && is.null(get_knitr_chunk(options$label))) {
      stop(
        "The exercise chunk '", options$label, "' doesn't have anything inside of it. ",
        "Try adding empty line(s) inside the code chunk.",
        call. = FALSE
      )
    }

    # if this is an exercise chunk then set various options
    if (exercise_chunk) {

      # one time tutor initialization
      initialize_tutorial()

      options$echo <- TRUE
      options$include <- TRUE
      options$highlight <- FALSE
      options$comment <- NA
      if (!is.null(options$exercise.eval))
        options$eval <- options$exercise.eval
      else
        options$eval <- FALSE
      # exercises can be support chunks, but if it's an exercise it should be treated that way
      return(options)
    }

    # if this is an exercise support chunk then force echo, but don't
    # eval or highlight it
    if (exercise_support_chunk) {
      options$echo <- TRUE
      options$include <- TRUE
      options$eval <- FALSE
      options$highlight <- FALSE
    }

    if (is_exercise_support_chunk(options, type = c("code-check", "error-check", "check"))) {
      options$include <- FALSE
    }

    if (is_exercise_support_chunk(options, type = "solution")) {
      # only print solution if exercise.reveal_solution is TRUE
      options$echo <- get_reveal_solution_option(options)
    }

    # if this is an exercise setup chunk then eval it if the corresponding
    # exercise chunk is going to be executed
    if (exercise_setup_chunk) {
      # figure out the default behavior
      exercise_eval <- knitr::opts_chunk$get('exercise.eval')
      if (is.null(exercise_eval))
        exercise_eval <- FALSE

      # look for chunks that name this as their setup chunk
      labels <- exercise_chunks_for_setup_chunk(options$label)
      if (grepl("-setup$", options$label))
        labels <- c(labels, sub("-setup$", "", options$label))
      labels <- paste0('"', labels, '"')
      labels <- paste0('c(', paste(labels, collapse = ', ') ,')')
      label_query <- paste0("knitr::all_labels(label %in% ", labels, ", ",
                            "identical(exercise.eval, ", !exercise_eval, "))")

      default_reversed <- length(eval(parse(text = label_query))) > 0
      if (default_reversed)
        exercise_eval <- !exercise_eval

      # set the eval property as appropriate
      options$eval <- exercise_eval
      options$echo <- FALSE
    }

    # If this is an -error-check function, then make sure that -check chunk is provided
    if (
      is_exercise_support_chunk(options, type = "error-check") &&
        is.null(get_knitr_chunk(sub("-error", "", options$label)))
    ) {
      stop(
        "Exercise '", sub("-error-check", "", options$label), "': ",
        "a *-check chunk is required when using an *-error-check chunk, but",
        " '", sub("-error", "", options$label), "' was not found in the tutorial.",
        call. = FALSE
      )
    }

    # return modified options
    options
  }

  # hook to amend output for exercise related chunks
  tutorial_knit_hook <- function(before, options, envir) {

    # helper to produce an exercise wrapper div w/ the specified class
    exercise_wrapper_div <- function(suffix = NULL, extra_html = NULL) {
      # before exercise
      if (before) {
        if (!is.null(suffix))
          suffix <- paste0("-", suffix)
        class <- paste0("exercise", suffix)
        lines <- ifelse(is.numeric(options$exercise.lines),
                        options$exercise.lines, 0)
        completion  <- as.numeric(options$exercise.completion %||% 1 > 0)
        diagnostics <- as.numeric(options$exercise.diagnostics %||% 1 > 0)
        startover <- as.numeric(options$exercise.startover %||% 1 > 0)
        paste0('<div class="tutorial-', class,
               '" data-label="', options$label,
               '" data-completion="', completion,
               '" data-diagnostics="', diagnostics,
               '" data-startover="', startover,
               '" data-lines="', lines, '">')
      }
      # after exercise
      else {
        c(extra_html, '</div>')
      }
    }

    # handle exercise chunks
    if (is_exercise_chunk(options)) {

      # one-time dependencies/server code
      extra_html <- NULL
      if (before) {

        # verify the chunk has a label if required
        verify_tutorial_chunk_label()

        # inject ace and clipboardjs dependencies
        knitr::knit_meta_add(list(
          list(ace_html_dependency()),
          list(clipboardjs_html_dependency())
        ))

        # write server code
        exercise_server_chunk(options$label)
      }
      else {
        # forward a subset of standard knitr chunk options
        options$engine <- knitr_engine(options$engine)
        options$exercise.df_print <- options$exercise.df_print %||% knitr::opts_knit$get('rmarkdown.df_print') %||% "default"
        options$exercise.checker <- dput_to_string(options$exercise.checker)
        all_chunks <- get_all_chunks(options)

        code_check_chunk <- get_knitr_chunk(paste0(options$label, "-code-check"))
        error_check_chunk <- get_knitr_chunk(paste0(options$label, "-error-check"))
        check_chunk <- get_knitr_chunk(paste0(options$label, "-check"))
        solution <- get_knitr_chunk(paste0(options$label, "-solution"))

        # remove class of "knitr_strict_list" so (de)serializing works properly for external evaluators
        class(options) <- NULL
        # we collect all the setup code to make exercise compatible with old learnr
        # note: this means that chained setup chunks will not work for non-R exercises
        # Remove this after v0.13 is released
        all_setup_code <- NULL
        if (length(all_chunks) > 1) {
          all_setup_code <- paste0(
            vapply(all_chunks[-length(all_chunks)], function(x) x$code, character(1)),
            collapse = "\n"
          )
        }

        exercise_cache <- structure(
          list(
            global_setup = get_setup_global_exercise(),
            setup = all_setup_code,
            chunks = all_chunks,
            code_check = code_check_chunk,
            error_check = error_check_chunk,
            check = check_chunk,
            solution  = solution,
            options = options[setdiff(names(options), "tutorial")],
            engine = options$engine
          ),
          class = "tutorial_exercise"
        )

        # serialize the list of chunks to server
        rmarkdown::shiny_prerendered_chunk(
          'server',
          sprintf(
            'learnr:::store_exercise_cache(%s)',
            dput_to_string(exercise_cache)
          )
        )

        # script tag with knit options for this chunk
        caption <-
          if (!is.null(options$exercise.cap)) {
            as.character(options$exercise.cap)
          } else {
            cap_engine <- knitr_engine(options$engine)

            # use logo shipped within learnr pkg (currently none)
            cap_engine_file <- system.file(file.path("internals", "icons", paste0(cap_engine, ".svg")), package = "learnr")
            if (file.exists(cap_engine_file)) {
              as.character(htmltools::div(
                class = "tutorial_engine_icon",
                htmltools::HTML(readLines(cap_engine_file))
              ))
            } else {
              cap_engine_val <-
                switch(cap_engine,
                  "bash" = "Bash",
                  "c" = "C",
                  "coffee" = "CoffeeScript",
                  "cc" = "C++",
                  "css" = "CSS",
                  "go" = "Go",
                  "groovy" = "Groovy",
                  "haskell" = "Haskell",
                  "js" = "JavaScript",
                  "mysql" = "MySQL",
                  "node" = "Node.js",
                  "octave" = "Octave",
                  "psql" = "PostgreSQL",
                  "python" = "Python",
                  "r" = "R",
                  "rcpp" = "Rcpp",
                  "cpp11" = "cpp11",
                  "rscript" = "Rscript",
                  "ruby" = "Ruby",
                  "perl" = "Perl",
                  "sass" = "Sass",
                  "scala" = "Scala",
                  "scss" = "SCSS",
                  "sql" = "SQL",
                  # else, return as the user provided
                  options$engine
                )
              i18n_span(
                "text.enginecap",
                paste(cap_engine_val, "Code"),
                opts = list(engine = cap_engine_val)
              )
            }
          }
        ui_options <- list(
          engine = options$engine,
          has_checker = (!is.null(check_chunk) || !is.null(code_check_chunk)),
          caption = as.character(caption)
        )
        extra_html <- c('<script type="application/json" data-ui-opts="1">',
                        jsonlite::toJSON(ui_options, auto_unbox = TRUE),
                        '</script>')
      }

      # wrapper div (called for before and after)
      exercise_wrapper_div(extra_html = extra_html)
    }

    # handle exercise support chunks (hints, solution)
    else if (is_exercise_support_chunk(options)) {

      # setup and checking code (-setup, -code-check, and -check) are included in exercise cache
      # do not send the setup and checking code to the browser

      # send hint and solution to the browser
      # these are visibly displayed in the UI
      if (is_exercise_support_chunk(options, type = c("hint", "hint-\\d+"))) {
        exercise_wrapper_div(suffix = "support")
      } else if (is_exercise_support_chunk(options, type = "solution")) {
        if (get_reveal_solution_option(options)) {
          exercise_wrapper_div(suffix = "support")
        }
      }

    }
  }

  list(
    # set global tutorial option which we can use as a basis for hooks
    # (this is so we don't collide with hooks set by the user or
    # by other packages or Rmd output formats)
    opts_chunk = list(tutorial = TRUE),
    opts_hooks = list(tutorial = tutorial_opts_hook),
    knit_hooks = list(tutorial = tutorial_knit_hook)
  )
}

install_knitr_hooks <- function() {
  knit_opts <- tutorial_knitr_options()
  knitr::opts_chunk$set(tutorial = knit_opts$opts_chunk$tutorial)
  knitr::opts_hooks$set(tutorial = knit_opts$opts_hooks$tutorial)
  knitr::knit_hooks$set(tutorial = knit_opts$knit_hooks$tutorial)
}

remove_knitr_hooks <- function() {
  knitr::opts_chunk$delete("tutorial")
  knitr::opts_hooks$delete("tutorial")
  knitr::knit_hooks$delete("tutorial")
}

exercise_server_chunk <- function(label) {
  # reactive for exercise execution
  rmarkdown::shiny_prerendered_chunk('server', sprintf(
'`tutorial-exercise-%s-result` <- learnr:::setup_exercise_handler(reactive(req(input$`tutorial-exercise-%s-code-editor`)), session)
output$`tutorial-exercise-%s-output` <- renderUI({
  `tutorial-exercise-%s-result`()
})', label, label, label, label))
}


verify_tutorial_chunk_label <- function() {
  if (!isTRUE(getOption("knitr.in.progress"))) return()

  label <- knitr::opts_current$get('label')
  unnamed_label <- knitr::opts_knit$get('unnamed.chunk.label')
  if (isTRUE(grepl(paste0('^', unnamed_label), label))) {
    stop("Code chunks with exercises or quiz questions must be labeled.",
         call. = FALSE)
  }
  not_valid_char_regex <- "[^a-zA-Z0-9_-]"
  if (grepl(not_valid_char_regex, label)) {
    stop(
      "Code chunks labels for exercises or quiz questions must only be labeled using:",
      "\n\tlower case letters: a-z",
      "\n\tupper case letters: A-Z",
      "\n\tnumbers case letters: 0-9",
      "\n\tunderscore: _",
      "\n\tdash: -",
      "\n\nCurrent label: \"", label ,"\"",
      "\n\nTry using: \"", gsub(not_valid_char_regex, "_", label) ,"\"",
      call. = FALSE
    )
  }
}
