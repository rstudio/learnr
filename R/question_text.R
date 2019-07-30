#' Text box question
#'
#' Creates a text box group tutorial quiz question.
#'
#'
#' @inheritParams question
#' @inheritParams shiny::textInput
#' @param ... answers and extra parameters passed onto \code{\link{question}}.
#' @param trim Logical to determine if whitespace before and after the answer should be removed.  Defaults to \code{TRUE}.
#' @seealso \code{\link{question_radio}}, \code{\link{question_checkbox}}
#' @importFrom utils modifyList
#' @export
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
  options = list()
) {
  checkmate::assert_character(placeholder, len = 1, null.ok = TRUE, any.missing = FALSE)
  checkmate::assert_logical(trim, len = 1, null.ok = FALSE, any.missing = FALSE)

  learnr::question(
    text = text,
    ...,
    type = "learnr_text",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = random_answer_order,
    options = modifyList(
      options,
      list(
        placeholder = placeholder,
        trim = trim
      )
    )
  )
}




question_ui_initialize.learnr_text <- function(question, value, ...) {
  textInput(
    question$ids$answer,
    label = question$question,
    placeholder = question$options$placeholder,
    value = value
  )
}


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


question_is_correct.learnr_text <- function(question, value, ...) {

  if (nchar(value) == 0) {
    showNotification("Please enter some text before submitting", type = "error")
    req(value)
  }

  if (isTRUE(question$options$trim)) {
    value <- str_trim(value)
  }

  for (ans in question$answers) {
    ans_val <- ans$label
    if (isTRUE(question$options$trim)) {
      ans_val <- str_trim(ans_val)
    }
    if (isTRUE(all.equal(ans_val, value))) {
      return(mark_as(
        ans$correct,
        ans$message
      ))
    }
  }

  mark_as(FALSE, NULL)
}

# question_ui_completed.learnr_text <- question_ui_completed.default
