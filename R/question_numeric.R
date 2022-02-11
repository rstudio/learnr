#' Number question
#'
#' Creates a tutorial question asking the student to submit a number.
#'
#' @examples
#' question_numeric(
#'   "What is pi rounded to 2 digits?",
#'   answer(3, message = "Don't forget to use the digits argument"),
#'   answer(3.1, message = "Too few digits"),
#'   answer(3.142, message = "Too many digits"),
#'   answer(3.14, correct = TRUE),
#'   allow_retry = TRUE,
#'   min = 3,
#'   max = 4,
#'   step = 0.01
#' )
#'
#' @param tolerance Submitted values within an absolute difference less than or
#'   equal to `tolerance` will be considered equal to the answer value. Note
#'   that this tolerance is for all [answer()] values. For more specific answer
#'   value grading, use [answer_fn()] to provide your own evaluation code.
#' @param ... Answers created with [answer()] or [answer_fn()], or extra
#'   parameters passed onto [question()].
#' @inheritParams question
#' @inheritParams shiny::numericInput
#'
#' @return Returns a learnr question of type `"learnr_numeric"`.
#'
#' @family Interactive Questions
#' @export
question_numeric <- function(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  value = NULL,
  min = NA,
  max = NA,
  step = NA,
  options = list(),
  tolerance = 1.5e-8
) {
  min  <- min  %||% NA_real_
  max  <- max  %||% NA_real_
  step <- step %||% NA_real_

  checkmate::assert_numeric(value, len = 1, null.ok = TRUE, any.missing = FALSE)
  checkmate::assert_numeric(min, len = 1, null.ok = FALSE)
  checkmate::assert_numeric(max, len = 1, null.ok = FALSE)
  checkmate::assert_numeric(step, len = 1, null.ok = FALSE, lower = 0, finite = TRUE)

  learnr::question(
    text = text,
    ...,
    type = "learnr_numeric",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = FALSE,
    options = utils::modifyList(
      options,
      list(
        value = value,
        min = min,
        max = max,
        step = step,
        tolerance = tolerance
      )
    )
  )
}



#' @export
question_ui_initialize.learnr_numeric <- function(question, value, ...) {
  numericInput(
    question$ids$answer,
    label = question$question,
    value = value,
    min = question$options$min,
    max = question$options$max,
    step = question$options$step
  )
}

#' @export
question_is_valid.learnr_numeric <- function(question, value, ...) {
  if (is.null(value)) {
    return(FALSE)
  }
  value <- suppressWarnings(as.numeric(value))
  !is.na(value)
}

#' @export
question_is_correct.learnr_numeric <- function(question, value, ...) {
  value <- suppressWarnings(as.numeric(value))

  if (length(value) == 0 || is.na(value)) {
    if (!is.null(shiny::getDefaultReactiveDomain())) {
      showNotification("Please enter a number before submitting", type = "error")
      req(value)
    } else {
      rlang::abort("`learnr_numeric` questions require numeric input values")
    }
  }

  tolerance <- question$options$tolerance %||% 1e-10

  compare_answer <- function(answer) {
    answer_value <- as.numeric(answer$value)
    if (isTRUE(abs(diff(c(answer_value, value))) <= tolerance)) {
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

  if (!is.na(question$options$min) && value < question$options$min) {
    return(mark_as(FALSE, paste0("The number is at least ", question$options$min, ".")))
  }
  if (!is.na(question$options$max) && value > question$options$max) {
    return(mark_as(FALSE, paste0("The number is at most ", question$options$max, ".")))
  }

  mark_as(FALSE, NULL)
}
