#' Checkbox question
#'
#' Creates a checkbox group tutorial quiz question.  The student may select one
#' or more checkboxes before submitting their answer.
#'
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
#'
#' # Set up a question where there's no wrong answer. The answer options are
#' # always shuffled, but the answer_fn() answer is always evaluated first.
#' question_checkbox(
#'   "Which of the tidyverse packages is your favorite?",
#'   answer("dplyr"),
#'   answer("tidyr"),
#'   answer("ggplot2"),
#'   answer("tibble"),
#'   answer("purrr"),
#'   answer("stringr"),
#'   answer("forcats"),
#'   answer("readr"),
#'   answer_fn(function(value) {
#'     if (length(value) == 1) {
#'       correct(paste(value, "is my favorite tidyverse package, too!"))
#'     } else {
#'       correct("Yeah, I can't pick just one favorite package either.")
#'     }
#'   }),
#'   random_answer_order = TRUE
#' )
#'
#' @inheritParams question
#' @param ... Answers created with [answer()] or [answer_fn()], or extra
#'   parameters passed onto [question()]. Function answers do not
#'   appear in the checklist, but are checked first in the order they are
#'   specified.
#'
#' @return Returns a learnr question of type `"learnr_checkbox"`.
#'
#' @family Interactive Questions
#' @export
question_checkbox <- function(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = "Incorrect. Be sure to select every correct answer.",
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

#' @export
question_ui_initialize.learnr_checkbox <- function(question, value, ...) {
  choice_names <- answer_labels(question, exclude_answer_fn = TRUE)
  choice_values <- answer_values(question, exclude_answer_fn = TRUE)

  checkboxGroupInput(
    question$ids$answer,
    inline = TRUE,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = value
  )
}


# question_is_valid.learnr_checkbox <- question_is_valid.default

#' @export
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

  q_answers <- answers_split_type(question$answers)

  # Check function answers first
  for (q_answer in q_answers[["function"]]) {
    answer_checker <- eval(parse(text = q_answer$value), envir = rlang::caller_env())
    ret <- answer_checker(value)
    if (inherits(ret, "learnr_mark_as")) {
      return(ret)
    }
  }

  # Follow up with literal answers
  value_is_correct <- TRUE
  for (q_answer in q_answers[["literal"]]) {
    ans_is_checked <- q_answer$option %in% value
    if (ans_is_checked && q_answer$correct) {
      # answer is checked and is correct
      # do nothing
    } else if ((!ans_is_checked) && (!q_answer$correct)) {
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
    for (q_answer in q_answers[["literal"]]) {
      if (q_answer$correct) {
        ret_messages <- append_message(ret_messages, q_answer)
      }
    }
  } else {
    # not all correct answers selected. get all selected "wrong" messages
    for (q_answer in q_answers[["literal"]]) {
      # get "wrong" answers
      if (!q_answer$correct) {
        # get selected answer
        ans_is_checked <- q_answer$option %in% value
        if (ans_is_checked) {
          ret_messages <- append_message(ret_messages, q_answer)
        }
      }
    }
  }

  mark_as(value_is_correct, ret_messages)
}

#' @export
question_ui_completed.learnr_checkbox <- function(question, value, ...) {

  choice_values <- answer_values(question, exclude_answer_fn = TRUE)

  answers <- answers_split_type(question$answers)[["literal"]]

  correct_answers <- Reduce(answers, init = c(), f = function(acc, answer) {
    if (!isTRUE(answer$correct)) return(acc)
    c(acc, answer$option)
  })

  is_value_all_correct <- identical(sort(correct_answers), sort(value))

  # update select answers to have X or √
  choice_names_final <- lapply(answers, function(q_answer) {
    is_q_answer_correct <- isTRUE(q_answer$correct)
    is_answer_picked <- q_answer$option %in% value

    tagClass <-
      if (is_q_answer_correct) {
        if (is_answer_picked) {
          "correct"
        }
      } else if (is_value_all_correct || is_answer_picked) {
        # only reveal complete solution when all right answers were picked
        "incorrect"
      }

    tags$span(q_answer$label, class = tagClass)
  })

  finalize_question(
    checkboxGroupInput(
      question$ids$answer,
      label = question$question,
      inline = TRUE,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = value
    )
  )
}
