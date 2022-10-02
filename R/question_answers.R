#' Question answer options
#'
#' Create options for users when used in [question_checkbox()] and
#' [question_radio()] learnr questions. For [question_text()] and
#' [question_numeric()], the individual answers aren't directly presented to
#' students, but their values can be used in determining if the student
#' submitted the correct answer. For flexible feedback from checkbox, text, and
#' numeric questions, `answer_fn()` can be used to provide a function that
#' evaluates the student's submission and returns a custom result.
#'
#' @examples
#' answer(32, correct = FALSE)
#' answer(42, correct = TRUE, message = "The meaning of life.")
#'
#' @param text The answer text or value; for selection-type questions this value
#'   is shown to the user.
#' @param fn A function used to evaluate the submitted answer. The function is
#'   called with the student's submitted value as the first argument, so the
#'   function should take at least one argument where the user's value will be
#'   passed to the first argument. Inline \pkg{purrr}-style lambda functions
#'   are allowed, see [rlang::as_function()] for complete details on the syntax.
#'
#'   In the body of the function, you can perform arbitrary calculations to
#'   decide if the submitted answer is or is not correct and to compose the
#'   message presented to the user. To signal a final answer, call [mark_as()]
#'   or its helper functions [correct()] or [incorrect()]. All other return
#'   values are ignored; e.g. by returning `NULL` you may yield the submission
#'   evaluation to other [answer()] or [answer_fn()] options for the question.
#' @param correct Logical value indicating whether the `answer()` corresponds to
#'   a correct or incorrect option.
#' @param message A custom message shown when this answer is selected and when
#'   the overall question result matches the state of this answer. For example,
#'   the `message` of a correct solution is not shown when the entire submission
#'   is incorrect, but _will_ be shown when the user both picks this answer
#'   option and the question is _correct_.
#' @param label The label shown when the option is presented to the user.
#'
#' @return Returns a list with the `"tutorial_question_answer"` class.
#'
#' @describeIn answer Create an answer option
#' @export
answer <- function(text, correct = FALSE, message = NULL, label = text) {
  if (!is_html_tag(message)) {
    checkmate::assert_character(message, len = 1, null.ok = TRUE, any.missing = FALSE)
  }

  answer_new(
    value = text,
    correct = isTRUE(correct),
    message = message,
    label = label,
    type = "literal"
  )
}

#' @describeIn answer Evaluate the student's submission to determine correctness
#'   and to return feedback.
#' @export
answer_fn <- function(fn, label = NULL) {
  fn <- rlang::as_function(fn, env = parent.frame())
  checkmate::assert_function(fn)
  if (!rlang::has_length(rlang::fn_fmls(fn))) {
    rlang::abort("`answer_fn()` requires a function with at least 1 argument.")
  }
  fn_text <- rlang::expr_text(fn)

  # `correct` and `message` will be provided by the function
  answer_new(
    value = fn_text,
    label = label,
    type = "function"
  )
}

#' @noRd
#' @param value The literal value to be directly compared with the user's
#'   submission, if a literal comparison is required.
#' @param label The text shown to the user for this answer in the UI
#' @param option A character value of the answer, paired with the label in the
#'   UI. When used (checkbox/radio), this is the value that comes back to the
#'   Shiny app as the user's submission.
#' @param correct This answer is correct, or not. Can only be `NULL` when
#'   `type = "function"`.
#' @param message A message to be presented to the user when they select this
#'   answer, if their entire submission state matches the answer correctness.
#' @param type Is this a literal answer (directly compare with `option` or `value`)
#'   or is this a function to evaluate the submission.
answer_new <- function(
    value,
    label = value,
    option = as.character(value),
    correct = NULL,
    message = NULL,
    type = "literal"
) {
  if (!is.character(option)) {
    option <- as.character(option)
  }

  ret <- list(
    id = random_answer_id(),
    option = option,
    value = value,
    label = quiz_text(label), # md -> html
    correct = correct,
    message = quiz_text(message),
    type = type
  )
  class(ret) <- c(
    "tutorial_question_answer", # new and improved name
    "tutorial_quiz_answer" # legacy. Want to remove
  )
  ret
}

random_answer_id <- function() {
  random_id("lnr_ans")
}


#' Mark submission as correct or incorrect
#'
#' Helper method to communicate that the user's submission was correct or
#' incorrect. These functions were originally designed for developers to create
#' [question_is_correct()] methods for custom question types, but they can also
#' be called inside the functions created by [answer_fn()] to dynamically
#' determine the result and message provided to the user.
#'
#' @examples
#' # Radio button question implementation of `question_is_correct`
#' question_is_correct.radio <- function(question, value, ...) {
#'   for (ans in question$answers) {
#'     if (as.character(ans$option) == value) {
#'       return(mark_as(ans$correct, ans$message))
#'     }
#'   }
#'   mark_as(FALSE, NULL)
#' }
#'
#' @param correct Logical: is the question answer is correct
#' @param messages A vector of messages to be displayed.  The type of message
#'   will be determined by the `correct` value. Note that markdown messages are
#'   not rendered into HTML, but you may provide HTML using [htmltools::HTML()]
#'   or [htmltools::tags].
#'
#' @return Returns a list with class `learnr_mark_as` to be returned from the
#'   [question_is_correct()] method for the learnr question type.
#'
#' @seealso [answer_fn()]
#' @rdname mark_as_correct_incorrect
#' @export
correct <- function(messages = NULL) {
  mark_as(correct = TRUE, messages = messages)
}

#' @rdname mark_as_correct_incorrect
#' @export
incorrect <- function(messages = NULL) {
  mark_as(correct = FALSE, messages = messages)
}

#' @rdname mark_as_correct_incorrect
#' @export
mark_as <- function(correct, messages = NULL) {
  checkmate::assert_logical(correct, len = 1, null.ok = FALSE, any.missing = FALSE)
  ret <- list(
    correct = correct,
    messages = messages
  )
  class(ret) <- "learnr_mark_as"
  ret
}

answer_type_is_function <- function(answers) {
  is_fn_answer <- function(x) identical(x$type, "function")
  vapply(answers, is_fn_answer, logical(1))
}

answers_split_type <- function(answers) {
  split(answers, vapply(answers, `[[`, character(1), "type"))
}

answer_labels <- function(question, exclude_answer_fn = FALSE) {
  answers <- question$answers
  if (isTRUE(exclude_answer_fn)) {
    answers <- answers[!answer_type_is_function(answers)]
  }
  lapply(answers, `[[`, "label")
}

answer_values <- function(question, exclude_answer_fn = FALSE) {
  answers <- question$answers
  if (isTRUE(exclude_answer_fn)) {
    answers <- answers[!answer_type_is_function(answers)]
  }
  ret <- lapply(
    # return the character string input.  This _should_ be unique
    lapply(answers, `[[`, "option"),
    as.character
  )
  if (length(unlist(unique(ret))) != length(ret)) {
    stop("Answer `option` values are not unique.  Unique values are required")
  }
  ret
}
