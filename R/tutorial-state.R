tutorial_cache_env <- new.env(parent = emptyenv())

prepare_tutorial_state <- function(session) {
  clear_tutorial_cache()
  session$userData$tutorial_state <- reactiveValues()
}

clear_tutorial_cache <- function() {
  assign("objects", list(), tutorial_cache_env)
  tutorial_cache_env$setup <- NULL
  invisible(TRUE)
}

store_tutorial_cache <- function(name, object, overwrite = FALSE) {
  if (!overwrite && name %in% names(tutorial_cache_env$objects)) {
    return(FALSE)
  }
  if (is.null(object)){
    return(FALSE)
  }
  tutorial_cache_env$objects[[name]] <- object
  TRUE
}

get_tutorial_cache <- function(type = c("all", "question", "exercise")) {
  type <- match.arg(type)

  filter_type <- function(x) {
    inherits(x, paste0("tutorial_", type))
  }

  switch(
    type,
    "all" = tutorial_cache_env$objects,
    Filter(filter_type, tutorial_cache_env$objects)
  )
}


# Exercises ---------------------------------------------------------------

# Gets the global setup chunk to run for out-of-process evaluators.
get_global_setup <- function() {
  warning(
    "`get_global_setup()` is deprecated. The `global_setup` code is now ",
    "included in the exercise object."
  )
  ex <- get_exercise_cache()
  if (!length(ex)) {
    return("")
  }
  ex[[1]]$global_setup
}

# Store setup chunks for an exercise or non-exercise chunk.
store_exercise_cache <- function(exercise, overwrite = FALSE) {
  label <- exercise$options$label
  store_tutorial_cache(name = label, object = exercise, overwrite = overwrite)
}

# Return the exercise object from the cache for a given label
get_exercise_cache <- function(label = NULL){
  exercises <- get_tutorial_cache(type = "exercise")
  if (is.null(label)) {
    return(exercises)
  }
  exercises[[label]]
}

clear_exercise_cache_env <- function() {
  .Deprecated("clear_tutorial_cache")
  clear_tutorial_cache()
}

# For backwards compatibility, exercise_cache_env was previously called setup_chunks
clear_exercise_setup_chunks <- clear_exercise_cache_env


# Questions ---------------------------------------------------------------

store_question_cache <- function(question, overwrite = FALSE){
  label <- question$label
  store_tutorial_cache(name = label, object = question, overwrite = overwrite)
}

# Return a list of knitr chunks for a given exercise label (exercise + setup chunks).
get_question_cache <- function(label = NULL){
  questions <- get_tutorial_cache(type = "question")
  if (is.null(label)) {
    return(questions)
  }
  questions[[label]]
}

clear_question_cache_env <- function() {
  .Deprecated("clear_tutorial_cache")
  clear_tutorial_cache()
}


# Tutorial State ----------------------------------------------------------

#' Observe the user's progress in the tutorial
#'
#' @description
#' As a student progresses through a \pkg{learnr} tutorial, their progress is
#' stored in a Shiny reactive values list for their session (see
#' [shiny::reactiveValues()]). Without arguments, `get_tutorial_state()` returns
#' the full reactiveValues object that can be converted to a conventional list
#' with [shiny::reactiveValuesToList()]. If the `label` argument is provided,
#' the state of an individual question or exercise with that label is returned.
#'
#' Calling `get_tutorial_state()` introduces a reactive dependency on the state
#' of returned questions or exercises unless called within `isolate()`. Note
#' that `get_tutorial_state()` will only work for the tutorial author and must
#' be used in a reactive context, i.e. within [shiny::observe()],
#' [shiny::observeEvent()], or [shiny::reactive()]. Any logic observing the
#' user's tutorial state must be written inside a `context="server"` chunk in
#' the tutorial's R Markdown source.
#'
#' @param label A length-1 character label of the exercise or question.
#' @param session The `session` object passed to function given to
#'   `shinyServer.` Default is [shiny::getDefaultReactiveDomain()].
#'
#' @return A reactiveValues object or a single reactive value (if `label` is
#'   provided). The names of the full reactiveValues object correspond to the
#'   label of the question or exercise. Each item contains the following
#'   entries:
#'
#'   - `type`: One of `"question"` or `"exercise"`.
#'   - `answer`: A character vector containing the user's submitted answer(s).
#'   - `correct`: A logical indicating whether the user's answer was correct,
#'     or a logical `NA` if the submission was not checked for correctness.
#'   - `timestamp`: The time at which the user's submission was completed, as
#'     a character string in UTC, formatted as `"%F %H:%M:%OS3 %Z"`.
#'
#' @seealso [get_tutorial_info()]
#' @export
get_tutorial_state <- function(label = NULL, session = getDefaultReactiveDomain()) {
  object_labels <- names(get_tutorial_cache())
  if (is.null(label)) {
    state <- shiny::reactiveValuesToList(session$userData$tutorial_state)
    state[intersect(object_labels, names(state))]
  } else {
    session$userData$tutorial_state[[label]]
  }
}

set_tutorial_state <- function(label, data, session = getDefaultReactiveDomain()) {
  stopifnot(is.character(label))
  if (is.reactive(data)) {
    data <- data()
  }

  if (is.null(data)) {
    session$userData$tutorial_state[[label]] <- NULL
    return()
  }

  stopifnot(is.list(data))
  data$timestamp <- timestamp_utc()
  session$userData$tutorial_state[[label]] <- data
  invisible(data)
}


# Tutorial Info -----------------------------------------------------------

#' Get information about the current tutorial
#'
#' Returns information about the current tutorial. Ideally the function should
#' be evaluated in a Shiny context, i.e. in a chunk with option
#' `context = "server"`. Note that the values of this function may change after
#' the tutorial is completely initialized. If called in a non-reactive context,
#' `get_tutorial_info()` will return default values that will most likely
#' correspond to the current tutorial.
#'
#' @examples
#' tutorial_rmd <- system.file(
#'   "tutorials", "hello", "hello.Rmd", package = "learnr"
#' )
#' get_tutorial_info(tutorial_rmd)
#'
#' @inheritParams get_tutorial_state
#' @param tutorial_path Path to a tutorial `.Rmd` source file
#' @inheritDotParams rmarkdown::render -encoding -input -output_file
#' @inheritParams rmarkdown::yaml_front_matter
#'
#' @return Returns an ordinary list with the following elements:
#'
#'   - `tutorial_id`: The ID of the tutorial, auto-generated or from the
#'     `tutorial$id` key in the tutorial's YAML front matter.
#'   - `tutorial_version`: The tutorial's version, auto-generated or from the
#'     `tutorial$version` key in the tutorial's YAML front matter.
#'   - `items`: A data frame with columns `order`, `label`, `type` and `data`
#'     describing the items (questions and exercises) in the tutorial. This item
#'     is only available in the running tutorial, not during the static
#'     pre-render step.
#'   - `user_id`: The current user.
#'   - `learnr_version`: The current version of the running learnr package.
#'   - `language`: The current language of the tutorial, either as chosen by the
#'     user or as specified in the `language` item of the YAML front matter.
#'
#' @seealso [get_tutorial_state()]
#' @export
get_tutorial_info <- function(
  tutorial_path = NULL,
  session = getDefaultReactiveDomain(),
  ...,
  encoding = "UTF-8"
) {
  if (identical(Sys.getenv("LEARNR_EXERCISE_USER_CODE", ""), "TRUE")) {
    return()
  }

  if (!is.null(session) && !is.null(tutorial_path)) {
    warning(
      "The `tutorial_path` argument is ignored when `get_tutorial_info()` is ",
      "called inside a Shiny reactive domain."
    )
    tutorial_path <- NULL
  }

  if (!is.null(tutorial_path)) {
    is_html <- grepl("html?$", tolower(tutorial_path))
    if (is_html) {
      prepare_tutorial_cache_from_html(tutorial_path)
    } else {
      render_args <- list(..., encoding = encoding)
      prepare_tutorial_cache_from_source(tutorial_path, render_args)
    }
  }

  rmd_meta <- rmarkdown::metadata
  cache_meta <- rlang::env_get(tutorial_cache_env, "metadata", NULL)

  metadata <-
    if (!is.null(cache_meta)) {
      list(tutorial = cache_meta)
    } else if (!is.null(rmd_meta) && length(rmd_meta)) {
      rmd_meta
    } else if (!is.null(tutorial_path)) {
      tryCatch(
        rmarkdown::yaml_front_matter(tutorial_path, encoding = encoding),
        error = function(e) NULL
      )
    }

  tutorial_language <-
    if (is.list(metadata$output) && "learnr::tutorial" %in% names(metadata$output)) {
      language_front_matter <- metadata$output[["learnr::tutorial"]]$language
      # get default tutorial language from the yaml header
      i18n_process_language_options(language_front_matter)$language
    }

  read_session_request <- function(key) {
    if (is.null(session)) {
      value <- switch(
        key,
        "tutorial.tutorial_id" = metadata$tutorial$id %||%
          withr::with_dir(dirname(tutorial_path), default_tutorial_id()),
        "tutorial.tutorial_version" = metadata$tutorial$version %||% default_tutorial_version(),
        "tutorial.user_id" = default_user_id(),
        "tutorial.language" = tutorial_language %||% default_language(),
        NULL
      )
      return(value)
    }
    read_request(session, key)
  }

  list(
    tutorial_id = read_session_request("tutorial.tutorial_id"),
    tutorial_version = read_session_request("tutorial.tutorial_version"),
    items = describe_tutorial_items(),
    user_id = read_session_request("tutorial.user_id"),
    learnr_version = as.character(utils::packageVersion("learnr")),
    language = read_session_request("tutorial.language")
  )
}

get_tutorial_exercises <- function(tutorial_path, session = getDefaultReactiveDomain(), ...) {
  info <- get_tutorial_info(tutorial_path = tutorial_path, session = session, ...)
  items_exercises <- info$items[info$items$type == "exercise", ]
  ex <- items_exercises$data
  names(ex) <- items_exercises$label
  ex
}

describe_tutorial_items <- function() {
  if (!length(tutorial_cache_env$objects)) {
    return()
  }

  items <- list(
    label = names(tutorial_cache_env$objects),
    type = vapply(
      tutorial_cache_env$objects,
      FUN.VALUE = character(1),
      function(x) {
        if (inherits(x, "tutorial_exercise")) {
          "exercise"
        } else if (inherits(x, "tutorial_question")) {
          "question"
        } else {
          "other"
        }
      }
    ),
    data = I(unname(tutorial_cache_env$objects))
  )

  for (i in seq_along(items[["data"]])) {
    if (items[["type"]][[i]] != "exercise") next

    label <- items[["label"]][[i]]
    code_chunks <- Filter(
      x = items[["data"]][[i]][["chunks"]],
      function(chunks) {
        identical(chunks[["label"]], label)
      }
    )
    items[["data"]][[i]][["code"]] <- standardize_code(code_chunks[[1]]$code)
    items[["data"]][[i]][["version"]] <- current_exercise_version
  }

  items <- as.data.frame(items, stringsAsFactors = FALSE)
  class(items$data) <- "list"
  items$order <- seq_len(nrow(items))
  class(items) <- c("tbl_df", "tbl", "data.frame")
  items[c("order", "label", "type", "data")]
}


# Helpers -----------------------------------------------------------------

prepare_tutorial_cache_from_source <- function(path_rmd, render_args = NULL) {
  # 1. Render input Rmd in its directory but to a temp html file
  # 2. Extract prerendered chunks and filter to question/exercise chunks from html
  # 3. Evaluate the prerendered code to populate the tutorial cache
  # 4. Clean up files on exit
  path_rmd <- normalizePath(path_rmd)
  path_html <- file.path(dirname(path_rmd), basename(tempfile(fileext = ".html")))

  # remove html and supporting files on exit
  withr::defer({
    unlink(path_html)
    unlink(sub("[.]html$", "_files", path_html), recursive = TRUE)
  })

  default_render_args <- list(
    envir = new.env(parent = globalenv()),
    quiet = TRUE,
    clean = TRUE
  )

  render_args <- utils::modifyList(render_args %||% list(), default_render_args)
  render_args$input <- basename(path_rmd)
  render_args$output_file <- basename(path_html)

  withr::with_dir(dirname(path_rmd), {
    if (!detect_installed_knitr_hooks()) {
      install_knitr_hooks()
      withr::defer(remove_knitr_hooks())
    }

    do.call(rmarkdown::render, render_args)
  })

  prepare_tutorial_cache_from_html(path_html, path_rmd)
}

prepare_tutorial_cache_from_html <- function(path_html, path_rmd = NULL) {
  if (!utils::file_test("-f", path_html)) {
    rlang::abort(sprintf(gettext("'%s' is not an existing file"), path_html))
  }

  prerendered_extract_context <-
    getFromNamespace("shiny_prerendered_extract_context", ns = "rmarkdown")

  prerendered_chunks <-
    prerendered_extract_context(readLines(path_html), context = "server")

  prerendered_chunks <- parse(text = prerendered_chunks)

  is_cache_chunk <- vapply(
    prerendered_chunks,
    function(x) {
      as.character(x[[1]])[3] %in% c("store_exercise_cache", "question_prerendered_chunk")
    },
    logical(1)
  )

  clear_tutorial_cache()
  session <- shiny::MockShinySession$new()

  res <- vapply(
    prerendered_chunks[is_cache_chunk],
    FUN.VALUE = logical(1),
    function(x) {
      shiny::withReactiveDomain(NULL, {
        session <- session
        eval(x)
        TRUE
      })
    }
  )

  is_metadata_chunk <- imap_lgl(prerendered_chunks, function(x, ...) {
    identical(as.character(x[[1]])[3], "register_http_handlers") &&
      "metadata" %in% names(x)
  })

  metadata <- NULL
  idx_metadata_chunk <- which(is_metadata_chunk)
  if (length(idx_metadata_chunk) > 0) {
    idx_metadata_chunk <- idx_metadata_chunk[[1]]
    env <- rlang::env(session = NULL)
    metadata <- eval(prerendered_chunks[idx_metadata_chunk][["metadata"]], envir = env)
  }

  assign("metadata", metadata, envir = tutorial_cache_env)

  ret <- rlang::env_get_list(tutorial_cache_env, c("objects", "metadata"), NULL)
  names(ret) <- c("items", "metadata")
  invisible(ret)
}
