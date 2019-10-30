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
    type = "learnr_checkbox",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = random_answer_order
  )
}


question_ui_initialize.learnr_checkbox <- function(question, value, ...) {
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


# question_is_valid.learnr_checkbox <- question_is_valid.default


question_is_correct.learnr_checkbox <- function(question, value, ...) {

  append_message <- function(x, ans) {
    message <- ans$message
    if (is.null(message)) {
      return(x)
    }
    if (length(x) == 0) {
      message
    } else {
      tagList(x, message)
    }
  }

  value_is_correct <- TRUE
  for (ans in question$answers) {
    ans_is_checked <- ans$option %in% value
    if (ans_is_checked && ans$correct) {
      # answer is checked and is correct
      # do nothing
    } else if ((!ans_is_checked) && (!ans$correct)) {
      # (answer is not checked) and (answer is not correct)
      # do nothing
    } else {
      value_is_correct <- FALSE
      # do not check remaining answers
      break
    }
  }

  ret_messages <- c()

  if (value_is_correct) {
    # selected all correct answers. get all good messages as all correct answers were selected
    for (ans in question$answers) {
      if (ans$correct) {
        ret_messages <- append_message(ret_messages, ans)
      }
    }

  } else {
    # not all correct answers selected. get all selected "wrong" messages
    for (ans in question$answers) {
      # get "wrong" answers
      if (!ans$correct) {
        # get selected answer
        ans_is_checked <- ans$option %in% value
        if (ans_is_checked) {
          ret_messages <- append_message(ret_messages, ans)
        }
      }
    }
  }

  return(mark_as(
    value_is_correct,
    ret_messages
  ))
}


question_ui_completed.learnr_checkbox <- function(question, value, ...) {

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
