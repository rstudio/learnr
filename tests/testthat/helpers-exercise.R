mock_exercise <- function(
  label = "ex",
  user_code = "",
  chunks = list(),
  engine = "r",
  global_setup = NULL,
  setup_label = NULL,
  solution_code = NULL,
  code_check = NULL,  # code_check_chunk
  error_check = NULL, # error_check_chunk
  check = NULL,       # check_chunk
  exercise.checker = dput_to_string(debug_exercise_checker),
  exercise.error.check.code = dput_to_string(debug_exercise_checker),
  exercise.df_print = "default",
  exercise.warn_invisible = TRUE,
  exercise.timelimit = 10,
  fig.height = 4,
  fig.width = 6.5,
  fig.retina = 2,
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
    tutorial = TRUE,
    max.print = 1000,
    exercise.checker = exercise.checker,
    label = label,
    exercise = TRUE,
    exercise.setup = setup_label,
    code = user_code,
    fig.num = 0,
    exercise.df_print = exercise.df_print,
    exercise.warn_invisible = exercise.warn_invisible,
    exercise.timelimit = exercise.timelimit
  )

  has_exercise_chunk <- any(
    vapply(chunks, `[[`, logical(1), c("opts", "exercise"))
  )

  if (!has_exercise_chunk) {
    chunks <- c(chunks, list(
      mock_chunk(
        label,
        user_code,
        exercise = TRUE,
        engine = engine,
        exercise.setup = setup_label
      )
    ))
  }

  list(
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
    options = utils::modifyList(default_options, list(...)),
    engine = engine,
    version = "1"
  )
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

mock_chunk <- function(label, code, exercise = FALSE, engine = "r", ...) {
  opts <- list(...)
  opts$label <- label
  opts$exercise <- exercise

  list(
    label = label,
    code = paste(code, collapse = "\n"),
    opts = opts,
    engine = engine
  )
}
