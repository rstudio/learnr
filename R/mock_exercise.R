#' Mock a learnr interactive exercise
#'
#' Creates an interactive exercise object that can be used in tests without
#' having to create a learnr tutorial.
#'
#' @examples
#' mock_exercise(
#'   user_code = "1 + 1",
#'   solution_code = "2 + 2",
#'   label = "two-plus-two"
#' )
#'
#' # Global Setup
#' mock_exercise(
#'   user_code = 'storms %>% filter(name = "Roxanne")',
#'   solution_code = 'storms %>% filter(name == "Roxanne")',
#'   global_setup = 'library(learnr)\nlibrary(dplyr)',
#'   label = "filter-storms"
#' )
#'
#' # Chained setup chunks
#' mock_exercise(
#'   user_code = "roxanne",
#'   solution_code = "roxanne %>%
#'   group_by(year, month, day) %>%
#'   summarize(wind = mean(wind))",
#'   chunks = list(
#'     mock_chunk(
#'       label = "prep-roxanne",
#'       code = 'roxanne <- storms %>% filter(name == "Roxanne")'
#'     )
#'   ),
#'   setup_label = "prep-roxanne",
#'   global_setup = "library(learnr)\nlibrary(dplyr)"
#' )
#'
#' @param user_code,solution_code,global_setup The user, solution, and global setup code, as strings.
#' @param label The label of the exercise.
#' @param engine The knitr language engine used by the exercise, equivalent to
#'   the engine used for the chunk with `exercise = TRUE` in a tutorial.
#' @param chunks A list of chunks to use for the exercise. Use `mock_chunk()`
#'   to create chunks.
#' @param setup_label The label of the chunk that contains the setup code. The
#'   chunk itself should be among the list of chunks provided to the `chunks`
#'   argument and the label of the setup chunk needs to match the label provided
#'   to `setup_label`.
#' @param check,code_check,error_check The checking code, as a string, that
#'   would typically be provided in the `-check`, `-code-check` and
#'  `-error-check` chunks in a learnr tutorial.
#' @param exercise.checker The exercise checker function, as a string. By
#'   default, a debug exercise checker is set but will only be used if any of
#'   `check`, `code_check` or `error_check` are provided.
#' @param exercise.error.check.code The default code used for `error_check` and
#'   applied only when `check` or `code_check` are provided and the user's code
#'   throws an error.
#' @param exercise.df_print,exercise.warn_invisible,exercise.timelimit,fig.height,fig.width,fig.retina
#'   Common exercise chunk options.
#' @param version The exercise version to emulate, by default `mock_exercise()`
#'   will return an exercise that matches the current exercise version.
#' @param ... Additional chunk options as if there were included in the
#'   exercise chunk.
#'
#' @describeIn mock_exercise Create a learnr exercise object
#' @keywords internal
#' @export
mock_exercise <- function(
  user_code = "1 + 1",
  label = "ex",
  chunks = list(),
  engine = "r",
  global_setup = NULL,
  setup_label = NULL,
  solution_code = NULL,
  code_check = NULL,  # code_check chunk
  error_check = NULL, # error_check chunk
  check = NULL,       # check chunk
  tests = NULL,       # tests chunk
  exercise.checker = NULL,
  exercise.error.check.code = NULL,
  exercise.df_print = "default",
  exercise.warn_invisible = TRUE,
  exercise.timelimit = 10,
  fig.height = 4,
  fig.width = 6.5,
  fig.retina = 2,
  version = current_exercise_version,
  ...
) {
  default_options <- list(
    eval = FALSE,
    echo = TRUE,
    results = "markup",
    tidy = FALSE,
    collapse = FALSE,
    prompt = FALSE,
    comment = NA,
    highlight = FALSE,
    fig.width = fig.width,
    fig.height = fig.height,
    fig.retina = fig.retina,
    engine = engine,
    max.print = 1000,
    exercise.checker = exercise.checker %||% dput_to_string(debug_exercise_checker),
    label = label,
    exercise = TRUE,
    exercise.setup = setup_label,
    code = user_code,
    fig.num = 0,
    exercise.df_print = exercise.df_print,
    exercise.warn_invisible = exercise.warn_invisible,
    exercise.timelimit = exercise.timelimit,
    exercise.error.check.code = exercise.error.check.code %||% dput_to_string(debug_exercise_checker)
  )

  assert_unique_exercise_chunk_labels(chunks, label)

  # create non-existent exercise chunk from global options
  chunks <- c(chunks, list(
    mock_chunk(
      label,
      user_code,
      exercise = TRUE,
      engine = engine,
      exercise.setup = setup_label,
      ...
    )
  ))

  assert_unique_chunk_labels(chunks)

  ex <- list(
    label = label,
    code = user_code,
    restore = FALSE,
    timestamp = as.numeric(Sys.time()),
    global_setup = paste(global_setup, collapse = "\n"), # added by get_global_setup()
    setup = mock_prep_setup(chunks, setup_label),        # walk setup chain
    chunks = chunks,
    solution = solution_code,
    code_check = code_check,
    error_check = error_check,
    check = check,
    tests = tests,
    options = utils::modifyList(default_options, list(...)),
    engine = engine,
    version = version
  )

  stopifnot(is.null(version) || length(version) == 1)
  if (!is.null(version) && version %in% c("2", "3")) {
    ex$tutorial <- list(
      id = "mock_tutorial_id",
      version = "9.9.9",
      user_id = "the_learnr",
      learnr_version = as.character(utils::packageVersion("learnr"))
    )
    if (version == "3") {
      ex$tutorial$language <- "en"
    }
  }

  class <- c("mock_exercise", "tutorial_exercise")
  if (version == 4) {
    class <- c(engine, class)
  }

  structure(ex, class = class)
}

assert_unique_exercise_chunk_labels <- function(chunks, label) {
  is_exercise_chunk <- vapply(chunks, FUN.VALUE = logical(1), function(x) {
    exercise <- x[[c("opts", "exercise")]]
    isTRUE(exercise)
  })
  if (!any(is_exercise_chunk)) {
    return()
  }
  exercise_chunk_labels <- vapply(chunks[is_exercise_chunk], `[[`, character(1), "label")
  n_ex_label_chunks <- sum(exercise_chunk_labels == label)
  if (n_ex_label_chunks == 0) {
    return()
  }

  rlang::abort(c(
    "The exercise `label` must be unique",
    x = sprintf(
      "%s chunk%s the same label as the exercise chunk: '%s'",
      n_ex_label_chunks,
      if (n_ex_label_chunks > 1) "s have" else " has",
      label
    )
  ))
}

assert_unique_chunk_labels <- function(chunks) {
  chunk_labels <- vapply(chunks, `[[`, character(1), "label")
  dups <- chunk_labels[duplicated(chunk_labels)]
  if (length(dups) == 0) {
    return()
  }
  rlang::abort(c(
    "Chunk labels must be unique",
    x = sprintf(
      "Duplicated label%s: '%s'",
      if (length(dups) != 1) "s" else "",
      paste(dups, collapse = "', '")
    )
  ))
}

mock_prep_setup <- function(chunks, setup_label) {
  if (is.null(setup_label) || identical(trimws(setup_label), "")) {
    return("")
  }
  chunk_labels <- vapply(chunks, `[[`, character(1), "label")
  if (!identical(unique(chunk_labels), chunk_labels)) {
    stop("Duplicated chunk labels: ", chunk_labels[duplicated(chunk_labels)])
  }
  setup <- c()
  visited_setup_chunks <- c()
  while (!is.null(setup_label)) {
    if (setup_label %in% visited_setup_chunks) {
      stop(
        "Cycles detected in setup chunks: ",
        paste(visited_setup_chunks, collapse = " -> "),
        " -> ", setup_label
      )
    }
    found_chunk <- FALSE
    for (chunk in chunks) {
      if (identical(chunk$label, setup_label)) {
        setup <- c(chunk$code, setup)
        visited_setup_chunks <- c(visited_setup_chunks, setup_label)
        setup_label <- chunk$opts[["exercise.setup"]]
        found_chunk <- TRUE
        break
      }
    }
    if (!found_chunk) {
      stop(setup_label, " is not in `chunks`.")
    }
  }
  paste(setup, collapse = "\n")
}

#' @describeIn mock_exercise Create a mock exercise-supporting chunk
#'
#' @param code In `mock_chunk()`, the code in the mocked chunk.
#' @param exercise In `mock_chunk()`, is this chunk the exercise chunk? If so,
#'   `mock_exercise()` will not create the exercise chunk for you.
#'
#' @keywords internal
#' @export
mock_chunk <- function(label, code, exercise = FALSE, engine = "r", ...) {
  opts <- list(...)
  opts$label <- label
  if (isTRUE(exercise)) {
    opts$exercise <- TRUE
  }

  if (is.null(opts[["exercise.setup"]])) {
    opts[["exercise.setup"]] <- NULL
  }

  list(
    label = label,
    code = paste(code, collapse = "\n"),
    opts = opts,
    engine = engine
  )
}

#' @export
format.mock_exercise <- function(x, ...) {
  # in real exercises, the chunk options are stored as un-evaluated strings
  x$chunks <- lapply(x$chunks, function(chunk) {
    if (!isTRUE(chunk$opts$exercise)) {
      chunk$opts$exercise <- NULL
    }
    chunk$opts <- vapply(chunk$opts, dput_to_string, character(1))
    chunk
  })
  class(x) <- "tutorial_exercise"
  format(x, ...)
}
