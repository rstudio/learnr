#' Checkbox question
#'
#' Creates a checkbox group tutorial quiz question.  The student may select one or more
#' checkboxes before submitting their answer.
#'
#'
#' @inheritParams question
#' @param ... answers and extra parameters passed onto \code{\link{question}}.
#' @seealso \code{\link{question_radio}}, \code{\link{question_text}}
#' @export
#' @examples
#' question_checkbox(
#'   "Select all the toppings that belong on a Margherita Pizza:",
#'   answer("tomato", correct = TRUE),
#'   answer("mozzarella", correct = TRUE),
#'   answer("basil", correct = TRUE),
#'   answer("extra virgin olive oil", correct = TRUE),
#'   answer("pepperoni", message = "Great topping! ... just not on a Margherita Pizza"),
#'   answer("onions"),
#'   answer("bacon"),
#'   answer("spinach"),
#'   random_answer_order = TRUE,
#'   allow_retry = TRUE,
#'   try_again = "Be sure to select all four toppings!"
#' )
question_checkbox <- function(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  random_answer_order = FALSE
) {
  learnr::question(
    text = text,
    ...,
    type = "checkbox",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = random_answer_order
  )
}


question_ui_initialize.checkbox <- function(question, value, ...) {
  choice_names <- answer_labels(question)
  choice_values <- answer_values(question)

  checkboxGroupInput(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = value
  )
}


# question_is_valid.checkbox <- question_is_valid.default


question_is_correct.checkbox <- function(question, value, ...) {

  append_message <- function(x, ans) {
    message <- ans$message
    if (is.null(message)) {
      return(x)
    }
    if (!is.list(message))  {
      message <- list(message)
    }
    if (length(x) == 0) {
      message
    } else {
      append(x, message)
    }
  }

  is_correct <- TRUE
  correct_messages <- list()
  incorrect_messages <- list()

  for (ans in question$answers) {
    ans_is_checked <- as.character(ans$option) %in% value
    submission_is_correct <-
      # is checked and is correct
      (ans_is_checked && ans$correct) ||
      # is not checked and is not correct
      ((!ans_is_checked) && (!ans$correct))

    if (submission_is_correct) {
      # only append messages if the box was checked
      if (ans_is_checked) {
        correct_messages <- append_message(correct_messages, ans)
      }
    } else {
      is_correct <- FALSE
      incorrect_messages <- append_message(incorrect_messages, ans)
    }
  }

  return(mark_as(
    is_correct,
    if (is_correct) correct_messages else incorrect_messages
  ))
}


question_ui_completed.checkbox <- function(question, value, ...) {

  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$correct) {
      tag <- " &#10003; "
      tagClass <- "correct"
    } else {
      tag <- " &#10007; "
      tagClass <- "incorrect"
    }
    tags$span(ans$label, HTML(tag), class = tagClass)
  })

  disable_all_tags(
    checkboxGroupInput(
      question$ids$answer,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = value
    )
  )
}
