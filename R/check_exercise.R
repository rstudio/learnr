
#######
# Functions extracted from the knitr hook
#######

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
is_exercise_support_chunk <- function(
  options,
  type = c(
    "setup",
    "hint",
    "hint-\\d+",
    "solution",
    "error-check",
    "code-check",
    "check"
  )
) {
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
  grepl("-setup$", label) ||
    (length(exercise_chunks_for_setup_chunk(label)) > 0)
}

#' Check the code from an Exercise
#'
#' This function will take all the chunks with a label that matches `setup` or
#' `-solution`, put them in a separate script and try to run them all.
#' This allows teachers to check that their setup and solution chunks
#' contain valid code.
#'
#' @param path Path to the Markdown file containing the RMarkdown.
#'
#' @return TRUE or FALSE invisibly.
#' @export
#'
#' @examples
#' if (interactive()){
#'   check_exercise("sandbox/sandbox")
#'   check_exercise("sandbox/sandbox-exos.Rmd")
#' }
check_exercise <- function(
  path
){

  path <- normalizePath(path)

  # set global tutorial option which we can use as a basis for hooks
  # (this is so we don't collide with hooks set by the user or
  # by other packages or Rmd output formats)
  knitr::opts_chunk$set(tutorial = TRUE)


  # The goal of this function is to check that a given
  # Rmd is correct, in the sense that the solution can be run
  # using the parameters that has been provided.
  # In other words, it tries to mimic the evaluation of an exercise
  # where the student's input == the teacher's solution
  #
  # Here is  how it achieves this
  # - parse a given Rmd
  # - create groups of chunk, based on their label:
  # setup, solution, and checkers
  # - reproduce the knitr context of evaluation
  # - for each group, run an evaluate_exercise(),
  # using the teacher's solution as an input
  # - If this evaluate_exercise() works, then the solution
  # is correct

  # Setting learnr options
  learnr::tutorial_options()

  # When exiting the fun, we delete all the code store
  # inside the knitr environment
  on.exit({
    knitr::knit_code$restore()
  })

  # Splitting the file using knitr.
  # This will register code inside  `knitr::knit_code`
  # The results is a list containing all the elements from the Rmd
  # (i.e code + title + yaml)
  res <- knitr:::split_file(
    xfun::read_utf8(path),
    patterns = knitr::all_patterns$md
  )

  # Given that we are in learnr, we only want the chunks that have a label
  # This should have the same length as knitr::knit_code$get()
  # For some reasons the result of split_file is not the same as what
  # knitr::knit_code$get() returns
  usefull_chunks <- res[
    ! vapply(
      res,
      function(.x) is.null(.x$params$label),
      FUN.VALUE = logical(1)
    )
  ]

  # Here length(knitr::knit_code$get()) == length(usefull_chunks)

  # Setting the names of the chunks using the labels
  names(usefull_chunks) <- vapply(
    usefull_chunks,
    function(.x) .x$params$label,
    FUN.VALUE = character(1)
  )
  # Here all(names(knitr::knit_code$get()) == names(usefull_chunks))

  # As the result of split_file does not contain the code, we add a code
  # elements
  for (i in seq_along(usefull_chunks)){

    usefull_chunks[[i]]$code <- knitr::knit_code$get(
      usefull_chunks[[i]]$params$label
    )

  }

  # We extract the default setup chunk, and remove it from the list
  setup_chunk <- usefull_chunks[["setup"]]
  usefull_chunks[["setup"]] <- NULL

  # At this point, all `usefull_chunks` contain two elements:
  # - params, which are the chunk parameters as a lit
  # - code, which contain the code and the parameters as attributes
  # We now need to build N exercise objects, we N is the number of
  # groups of chunks inside the Rmd
  #
  # Once we have successfully built the exercise object, we can
  # safely pass it to `evaluate_exercise`

  # Grep the "titles" of the groups. The length of this  object will
  # correspond to the number of time we'll build an exercise object
  # and evaluate_exercise() it
  chunks_ <- grep(
    "(-solution)|(-check)|(-hint)|(-setup)",
    names(usefull_chunks),
    invert = TRUE,
    value = TRUE
  )


  for (i in seq_along(usefull_chunks)){
    # Get all the knitr options
    options <- knitr::opts_chunk$get()
    # If any of this options is overriden at the chunk level,
    # we override it. The idea here is to be able to build a chunk
    # with all the options
    for (
      param in names(usefull_chunks[[i]]$params)
    ){
      options[[
        param
      ]] <- usefull_chunks[[i]]$params[[
        param
      ]]
    }

    # We set some options based on
    # https://github.com/rstudio/learnr/blob/master/R/knitr-hooks.R#L142
    exercise_chunk <- is_exercise_chunk(options)
    exercise_support_chunk <- is_exercise_support_chunk(options)
    exercise_setup_chunk <- is_exercise_support_chunk(options, type = "setup")

    if (exercise_chunk) {
      learnr:::initialize_tutorial()
      options$echo <- TRUE
      options$include <- TRUE
      options$highlight <- FALSE
      options$comment <- NA
      if (!is.null(options$exercise.eval)){
        options$eval <- options$exercise.eval
      } else {
        options$eval <- FALSE
      }

    }

    if (exercise_support_chunk) {
      options$echo <- TRUE
      options$include <- TRUE
      options$eval <- FALSE
      options$highlight <- FALSE
    }

    if (
      is_exercise_support_chunk(
        options,
        type = c("code-check", "error-check", "check")
      )
    ) {
      options$include <- FALSE
    }

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

      if (default_reversed) {
        exercise_eval <- !exercise_eval
      }


      # set the eval property as appropriate
      options$eval <- exercise_eval
      options$echo <- FALSE
    }

    # Add the options list to the chunk
    usefull_chunks[[i]]$options <- options

    # The exercise object will need a  label and the engine,
    # we set them both here
    usefull_chunks[[i]]$label <-  usefull_chunks[[i]]$params$label
    usefull_chunks[[i]]$engine <-
      usefull_chunks[[i]]$options$engine <- usefull_chunks[[i]]$params$engine %||% "r"

  }

  # Setting something to return that will be turned to FALSE
  # if any check fail
  all_passed <- TRUE

  # Now that we have manipulated the chunks, we can build the
  # exercise objects

  for (chunk_ in chunks_){
    # Restoring  knitr code stock
    knitr::knit_code$restore()
    # Grep all the related chunks (i.e setup, checker, etc)
    all_related <- grep(chunk_, names(usefull_chunks), value = TRUE)

    # If there is a setup chunk, we make sure it's the first of the list
    if (any(grepl("setup", all_related))){
      setup_ <- grepl("setup", all_related)
      all_related <- c(
        all_related[setup_],
        all_related[!setup_]
      )
    }

    # This function allow to grab a chunk based on
    # its pattern
    grab_chunk <- function(
      pattern
    ){
      res <- usefull_chunks[
        all_related[
          grepl(
            sprintf("%s-%s", chunk_, pattern),
            all_related
          )
        ]
      ]
      if (length(res)){
        return(res)
      }
      list(
        list()
      )
    }

    # Now we are building the exercise object, and it
    # will be sent to evaluate_code()
    #
    # An exercise object needs the following elements:
    # - exercise$label
    # - exercise$code, which will be the solution code here
    # - exercise$restore
    # - exercise$timestamp
    # - exercise$global_setup if any
    # - exercise$setup if any
    # - exercise$code_check if any
    # - exercise$chunks that contains the setup chunks
    # - exercise$check if any
    # - exercise$engine
    #

    # We keep the  chunk we need: setup, and solution
    chunks_needed <- list()

    if (length(grab_chunk("setup")[[1]])){
      chunks_needed[[1]] <- grab_chunk("setup")[[1]]
    }
    if (length(grab_chunk("solution")[[1]])){
      chunks_needed[[
        length(chunks_needed) + 1
      ]] <- grab_chunk("solution")[[1]]
    }
    exercise_blt <- list(
      # Getting the label
      label = {
        chunk_
      },
      code = {
        paste0(grab_chunk("solution")[[1]]$code, "\n\n", collapse = "\n")
      },
      restore = {
        FALSE
      },
      timestamp = {
        as.numeric(Sys.time())
      },
      global_setup = {
        paste0(setup_chunk$code, collapse = "\n")
      },
      setup = {
        paste0(grab_chunk("setup")[[1]]$code, collapse = "\n")
      },
      chunks = {
        chunks_needed
      },
      solution  = {
        grab_chunk("solution")[[1]]
      },
      code_check  = {
        # TODO
        #grab_chunk("code-check")[[1]]
      },
      options = {
        usefull_chunks[chunk_][[1]]$options
      },
      engine = {
        usefull_chunks[chunk_][[1]]$enginee %||% "r"
      },
      version = "1"
    )

    res <- evaluate_exercise(
      exercise_blt,
      envir = new.env()
    )
    if (is.null(res$error_message)){
      cli::cat_bullet(
        sprintf("Exercise '%s' checked", chunk_),
        bullet = "tick", bullet_col = "green", col = "green"
      )
    } else {
      cli::cat_bullet(
        sprintf("Exercise '%s' failed", chunk_),
        bullet = "tick",
        bullet_col = "red",
        col = "red"
      )
      print(res$error_message)
      all_passed <- FALSE
    }
  }

  return(invisible(all_passed))
}
