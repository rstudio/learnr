#' Anybox question
#'
#' Creates an anybox group tutorial quiz question.  The student may select one
#' or more checkboxes before submitting their answer. An alternative to the
#' checkbox group tutorial quiz question, if there are multiple correct answers,
#' you may choose the minimum number of correct responses and the maximum number
#' of incorrect responses required to successfully complete the question.
#'
#' Correct options should have a message which will display if the question is
#' passed with missed options.
#'
#'
#' @inheritParams question
#' @param min_right Minimum number of correct options which must be selected.
#' @param max_wrong Maximum number of incorrect options which may be selected.
#' @param ... answers and extra parameters passed onto \code{\link{question}}.
#' @seealso \code{\link{question_checkbox}} \code{\link{question_radio}},
#'   \code{\link{question_text}}
#' @export
#' @examples
#' question_anybox(
#'   "Select all the toppings that belong on a Margherita Pizza:",
#'   answer("tomato", correct = TRUE, message = "Tomatoes too!"),
#'   answer("mozzarella", correct = TRUE, "Don't forget the cheese!"),
#'   answer("basil", correct = TRUE, "Basil gives it a distinctive flavor!"),
#'   answer("extra virgin olive oil", correct = TRUE, "You need olive oil too!"),
#'   answer("pepperoni", message = "Great topping! ... just not on a Margherita Pizza"),
#'   answer("onions"),
#'   answer("bacon"),
#'   answer("spinach"),
#'   random_answer_order = TRUE,
#'   allow_retry = TRUE,
#'   try_again = "Be sure to select all four toppings!",
#'   min_right = 3,
#'   max_wrong = 1
#' )
question_anybox <- function(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  random_answer_order = FALSE,
  min_right = 1,
  max_wrong = 0
) {
  structure(learnr::question(
    text = text,
    ...,
    type = "learnr_anybox",
    correct = correct,
    incorrect = incorrect,
    allow_retry = allow_retry,
    random_answer_order = random_answer_order
  ), min_right = min_right, max_wrong = max_wrong)
}


question_ui_initialize.learnr_anybox <- function(question, value, ...) {
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

question_is_correct.learnr_anybox <- function(question, value, ...) {
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

  min_right <- max(attr(question, "min_right"), 1)
  max_wrong <- max(attr(question, "max_wrong"), 0)
  ans <- question[["answers"]]
  anss <- vapply(ans, `[[`, character(1), "option")
  corr <- vapply(ans, `[[`, logical(1), "correct")
  cor_ans <- anss[corr]
  check <- match(value, cor_ans)
  right <- cor_ans[na.omit(check)]
  wrong <- ans[match(setdiff(value, cor_ans), anss)]
  missed <- ans[match(setdiff(cor_ans, value), anss)]
  ret_messages <- NULL
  pass <- length(right) >= min_right &&  length(wrong) <= max_wrong
  if (pass) {
    for (miss in missed) {
      ret_messages <- append_message(ret_messages, miss)
    }
    for (bad in wrong) {
      ret_messages <- append_message(ret_messages, bad)
    }
  }
  mark_as(pass, ret_messages)
}

question_ui_completed.learnr_anybox <- function(question, value, ...) {
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
