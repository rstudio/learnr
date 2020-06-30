
install_knitr_hooks <- function() {

  # set global tutorial option which we can use as a basis for hooks
  # (this is so we don't collide with hooks set by the user or
  # by other packages or Rmd output formats)
  knitr::opts_chunk$set(tutorial = TRUE)

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
                                                          "code-check",
                                                          "check")) {
    support_regex <- paste0("-(", paste(type, collapse = "|"), ")$")
    if (grepl(support_regex, options$label)) {
      exercise_label <- sub(support_regex, "", options$label)
      label_query <- "knitr::all_labels(exercise == TRUE)"
      all_exercise_labels <- eval(parse(text = label_query))
      exercise_label %in% all_exercise_labels
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
        if (is.null(options$exercise) && !is.null(options$exercise.setup)) {
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
    code_query <- paste0("knitr::knit_code$get('", label, "')")
    # Note: we can get the raw, unevaluated chunk options, for e.g. `exercise=as.logical(1)`
    eval(parse(text = code_query))
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
    # remove empty lines from a setup chunk
    if (!is.null(setup_chunk)) {
      setup_attributes <- attributes(setup_chunk)
      setup_chunk <- paste0(setup_chunk, collapse = "\n")
      attributes(setup_chunk) <- setup_attributes
    }
    # if the setup_label is mispelled, throw an error to user instead of silently ignoring
    # which would cause other issues when data dependencies can't be found
    if (!is.null(setup_label) && is.null(setup_chunk))
      stop(paste0("exercise.setup label '", setup_label, "' not found for exercise '", options$label, "'"))
    # recurse
    setup_options <- attr(setup_chunk, "chunk_opts")
    parent_setup_chunks <- list()
    if (!is.null(setup_options))
      parent_setup_chunks <- list(setup_chunk)
    parent_setup_chunks <- append(find_parent_setup_chunks(setup_options, visited), parent_setup_chunks)
    parent_setup_chunks
  }

  # TODO-Nischal incorporate the exercise AND setup chunks into one list structure
  # could we structure of each chunk in a list structure instead?
  # item <- "x <- 2"
  # attributes(item) <- list(chunk_opts = list(label = "setupB"))
  # exercise_setup <- list(val = as.character(item), opts = attributes(item))
  # json <- jsonlite::toJSON(exercise_setup)
  # json
  # {"val":["x <- 2"],"opts":{"chunk_opts":{"label":["setupB"]}}}
  # helper function to return a list of exercise chunk and its setup chunks
  get_all_chunks <- function(options) {
    # get the exercise chunk
    current_chunk <- get_knitr_chunk(options$label)
    all_chunks <- list(current_chunk)
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
    all_chunks <- append(setup_chunks, all_chunks)
    all_chunks
  }

  # hook to turn off evaluation/highlighting for exercise related chunks
  knitr::opts_hooks$set(tutorial = function(options) {

    # check for chunk type
    exercise_chunk <- is_exercise_chunk(options)
    exercise_support_chunk <- is_exercise_support_chunk(options)
    exercise_setup_chunk <- is_exercise_support_chunk(options, type = "setup")

    # validate that we have runtime: shiny_prerendered
    if ((exercise_chunk || exercise_support_chunk) && !is_shiny_prerendered_active()) {
      stop("Tutorial exercises require the use of 'runtime: shiny_prerendered'",
           call. = FALSE)
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
    }

    # if this is an exercise support chunk then force echo, but don't
    # eval or highlight it
    if (exercise_support_chunk) {
      options$echo <- TRUE
      options$include <- TRUE
      options$eval <- FALSE
      options$highlight <- FALSE
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
    }

    # return modified options
    options
  })

  # hook to amend output for exercise related chunks
  knitr::knit_hooks$set(tutorial = function(before, options, envir) {

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
        caption <- ifelse(is.null(options$exercise.cap), "Code", options$exercise.cap)
        paste0('<div class="tutorial-', class,
               '" data-label="', options$label,
               '" data-caption="', caption,
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
        preserved_options <- list()
        preserved_options$fig.width <- options$fig.width
        preserved_options$fig.height <- options$fig.height
        preserved_options$fig.retina <- options$fig.retina
        preserved_options$fig.asp <- options$fig.asp
        preserved_options$fig.align <- options$fig.align
        preserved_options$fig.keep <- options$fig.keep
        preserved_options$fig.show <- options$fig.show
        preserved_options$fig.cap <- options$fig.cap
        preserved_options$out.width <- options$out.width
        preserved_options$out.height <- options$out.height
        preserved_options$out.extra <- options$out.extra
        preserved_options$warning <- options$warning
        preserved_options$error <- options$error
        preserved_options$message <- options$message

        # forward some exercise options
        preserved_options$exercise.df_print <- knitr::opts_knit$get('rmarkdown.df_print')
        if (is.null(preserved_options$exercise.df_print))
          preserved_options$exercise.df_print <- "default"
        preserved_options$exercise.timelimit <- options$exercise.timelimit
        preserved_options$exercise.setup <- options$exercise.setup
        preserved_options$engine <- knitr_engine(options$engine)
        preserved_options$exercise.checker <- deparse(options$exercise.checker)

        all_chunks <- get_all_chunks(options)
        # serialize the list of chunks to server
        rmarkdown::shiny_prerendered_chunk(
          'server',
          sprintf(
            'learnr:::store_exercise_chunks(%s, %s)',
            dput_to_string(options$label),
            dput_to_string(all_chunks)
          )
        )

        # script tag with knit options for this chunk
        extra_html <- c('<script type="application/json" data-opts-chunk="1">',
                        jsonlite::toJSON(preserved_options, auto_unbox = TRUE),
                        '</script>')
      }

      # wrapper div (called for before and after)
      exercise_wrapper_div(extra_html = extra_html)
    }

    # handle exercise support chunks (setup, solution, and check)
    else if (is_exercise_support_chunk(options)) {
      # Store setup chunks for later analysis
      if (before && is_exercise_setup_chunk(options$label)) {
        rmarkdown::shiny_prerendered_chunk(
          'server',
          sprintf(
            'learnr:::store_exercise_setup_chunk(%s, %s)',
            dput_to_string(options$label),
            dput_to_string(options$code)
          )
        )
      }

      # output wrapper div
      exercise_wrapper_div(suffix = "support")

    }

    # Possibly redundant with the new_source_knit_hook, but that hook skips
    # chunks that are empty. This makes it more likely that we catch the setup-
    # global-exercise chunk. We keep the source hook, however, because we want
    # to be less sensitive to the ordering of the chunks.
    else if (identical(options$label, "setup-global-exercise")){
      write_setup_chunk(options$code, TRUE)
    }

  })

  # Preserve any existing `source` hook
  # We generally namespace our hooks under `tutorial` by calling `opts_chunk$set(tutorial = TRUE)`.
  # Unfortunately, that only applies to subsequent chunks, not the current one.
  # Since learnr is typically loaded in the `setup` chunk and we want to capture
  # that chunk, that's unfortunately too late. Therefore we have to set a global
  # `source` chunk to capture setup. However, we do take precautions to preserve
  # any existing hook that might have been installed before creating our own.
  knitr_hook_cache$source <- knitr::knit_hooks$get("source")

  # Note: Empirically, this function gets called twice
  knitr::knit_hooks$set(source = new_source_knit_hook())

}

# cache to hold the original knit hook
knitr_hook_cache <- new.env(parent=emptyenv())

write_setup_chunk <- function(code, overwrite = FALSE){
  rmarkdown::shiny_prerendered_chunk(
    'server',
    sprintf(
      'learnr:::store_exercise_setup_chunk("__setup__", %s, overwrite = %s)',
      dput_to_string(code),
      overwrite
    )
  )
}

# takes in the write_set_chk which we can use to mock this side-effect in testing.
new_source_knit_hook <- function(write_set_chk = write_setup_chunk) {
  function(x, options) {
    # By configuring `setup` to not overwrite, and `setup-global-exercise` to
    # overwrite, we ensure that:
    #  1. If a chunk named `setup-global-exercise` exists, we use that
    #  2. If not, it would return the chunk named `setup` if it exists
    if (identical(options$label, "setup-global-exercise")){
      write_set_chk(options$code, TRUE)
    } else if (identical(options$label, "setup")){
      write_set_chk(options$code, FALSE)
    }

    if(!is.null(knitr_hook_cache$source)) {
      knitr_hook_cache$source(x, options)
    }
  }
}

remove_knitr_hooks <- function() {
  knitr::opts_hooks$set(tutorial = NULL)
  knitr::knit_hooks$set(tutorial = NULL)
  knitr::knit_hooks$set(source = knitr_hook_cache$source)
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
