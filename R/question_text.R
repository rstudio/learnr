#' Text box question
#'
#' @description
#' Creates a tutorial question asking the student to enter text. The default
#' text input is appropriate for short or single-line text entry. For longer
#' text input, set the `rows` and/or `cols` argument to create a larger text
#' area.
#'
#' When used with [answer()], the student's submission must match the answer
#' exactly, minus whitespace trimming if enabled with `trim = TRUE`. For more
#' complicated submission evaluation, use [answer_fn()] to provide a function
#' that checks the student's submission. For example, you could provide a
#' function that evaluates the user's submission using
#' [regular expressions][base::regex].
#'
#' @examples
#' question_text(
#'   "Please enter the word 'C0rrect' below:",
#'   answer("correct", message = "Don't forget to capitalize"),
#'   answer("c0rrect", message = "Don't forget to capitalize"),
#'   answer("Correct", message = "Is it really an 'o'?"),
#'   answer("C0rrect ", message = "Make sure you do not have a trailing space"),
#'   answer("C0rrect", correct = TRUE),
#'   allow_retry = TRUE,
#'   trim = FALSE
#' )
#'
#' @param rows,cols Defines the size of the text input area in terms of the
#'   number of rows or character columns visible to the user. If either `rows`
#'   or `cols` are provided, the quiz input will use [shiny::textAreaInput()]
#'   for the text input, otherwise the default input element is a single-line
#'   [shiny::textInput()].
#' @param trim Logical to determine if whitespace before and after the answer
#'   should be removed.  Defaults to `TRUE`.
#' @param random_answer_order `r lifecycle::badge('deprecated')` Random answer
#'   order for text questions is automatically disabled to ensure that the
#'   submission is checked against each answer in the order they were provided
#'   by the author.
#' @inheritParams question
#' @inheritParams shiny::textInput
#' @param ... Answers created with [answer()] or [answer_fn()], or extra
#'   parameters passed onto [question()]. Answers with custom function checking
#'
#' @return Returns a learnr question of type `"learnr_text"`.
#'
#' @family Interactive Questions
#' @export
question_text <- function(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  random_answer_order = FALSE,
  placeholder = "Enter answer here...",
  trim = TRUE,
  rows = NULL,
  cols = NULL,
  options = list()
) {
  checkmate::assert_character(placeholder, len = 1, null.ok = TRUE, any.missing = FALSE)
  checkmate::assert_logical(trim, len = 1, null.ok = FALSE, any.missing = FALSE)

  if (!identical(random_answer_order, FALSE)) {
    learnr_render_catch(
      lifecycle::deprecate_warn(
        when = "0.11.0",
        what = "question_text(random_answer_order)",
        details = c(i = "Random answer order is automatically disabled for text questions.")
      )
    )
  }

  learnr::question(
    text = text,
    ...,
    type = "learnr_text",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = FALSE,
    options = utils::modifyList(
      options,
      list(
        placeholder = placeholder,
        trim = trim,
        rows = rows,
        cols = cols
      )
    )
  )
}


#' @export
question_ui_initialize.learnr_text <- function(question, value, ...) {
  # Use textInput() unless one of rows or cols are provided
  textInputFn <-
    if (is.null(question$options$rows) && is.null(question$options$cols)) {
      textInput
    } else {
      function(...) {
        textAreaInput(..., cols = question$options$cols, rows = question$options$rows)
      }
    }

  textInputFn(
    question$ids$answer,
    label = question$question,
    placeholder = question$options$placeholder,
    value = value
  )
}

#' @export
question_is_valid.learnr_text <- function(question, value, ...) {
  if (is.null(value)) {
    return(FALSE)
  }
  if (isTRUE(question$options$trim)) {
    return(nchar(str_trim(value)) > 0)
  } else{
    return(nchar(value) > 0)
  }
}

#' @export
question_is_correct.learnr_text <- function(question, value, ...) {

  if (nchar(value) == 0) {
    if (!is.null(shiny::getDefaultReactiveDomain())) {
      showNotification("Please enter some text before submitting", type = "error")
    }
    shiny::validate("Please enter some text")
  }

  if (isTRUE(question$options$trim)) {
    value <- str_trim(value)
  }

  compare_answer <- function(answer) {
    answer_value <- answer$value
    if (isTRUE(question$options$trim)) {
      answer_value <- str_trim(answer_value)
    }
    if (isTRUE(all.equal(answer_value, value))) {
      mark_as(answer$correct, answer$message)
    }
  }

  check_answer <- function(answer) {
    answer_checker <- eval(parse(text = answer$value), envir = rlang::caller_env(2))
    answer_checker(value)
  }

  for (answer in question$answers) {
    ret <- switch(
      answer$type,
      "function" = check_answer(answer),
      compare_answer(answer)
    )
    if (inherits(ret, "learnr_mark_as")) {
      return(ret)
    }
  }

  mark_as(FALSE, NULL)
}

# question_ui_completed.learnr_text <- question_ui_completed.default
