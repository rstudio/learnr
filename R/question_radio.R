#' Radio question
#'
#' Creates a radio button tutorial quiz question. The student can select only
#' one radio button before submitting their answer. Note: Multiple correct
#' answers are allowed.
#'
#' @examples
#' question_radio(
#'   "Pick the letter B",
#'   answer("A"),
#'   answer("B", correct = TRUE),
#'   answer("C"),
#'   answer("D"),
#'   allow_retry = TRUE,
#'   random_answer_order = TRUE
#' )
#'
#' @inheritParams question
#' @param ... Answers created with [answer()] or extra parameters passed onto
#'   [question()]. Function answers are ignored for radio questions because the
#'   user is required to select a single answer.
#'
#' @return Returns a learnr question of type `"learnr_radio"`.
#'
#' @family Interactive Questions
#' @export
question_radio <- function(
    text,
    ...,
    correct = "Correct!",
    incorrect = "Incorrect",
    try_again = incorrect,
    allow_retry = FALSE,
    random_answer_order = FALSE
) {
  question <-
    learnr::question(
      text = text,
      ...,
      type = "learnr_radio",
      correct = correct,
      incorrect = incorrect,
      allow_retry = allow_retry,
      random_answer_order = random_answer_order
    )

  answer_is_fn <- answer_type_is_function(question$answers)
  if (any(answer_is_fn)) {
    rlang::warn(paste(
      "`question_radio()` does not support `answer_fn()` type answers",
      "because the user may only select a single answer."
    ))

    # question() already checked that we have one correct non-fn answer
    question$answers <- question$answers[!answer_is_fn]
  }

  question
}

#' @export
question_ui_initialize.learnr_radio <- function(question, value, ...) {

  choice_names <- answer_labels(question, exclude_answer_fn = TRUE)
  choice_values <- answer_values(question, exclude_answer_fn = TRUE)

  radioButtons(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = value %||% character(0) # avoid selecting the first item when value is NULL
  )
}

#' @export
question_is_correct.learnr_radio <- function(question, value, ...) {
  for (ans in question$answers) {
    if (as.character(ans$option) == value) {
      return(mark_as(
        ans$correct,
        ans$message
      ))
    }
  }
  mark_as(FALSE, NULL)
}


#' @export
question_ui_completed.learnr_radio <- function(question, value, ...) {
  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$correct) {
      tagClass <- "correct"
    } else {
      tagClass <- "incorrect"
    }
    tags$span(ans$label, class = tagClass)
  })

  finalize_question(
    radioButtons(
      question$ids$answer,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = value
    )
  )
}
