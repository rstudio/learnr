#' @rdname quiz
#' @export
answer <- function(text, correct = FALSE, message = NULL) {
  if (!is.character(text)) {
    stop("Non-string `text` values are not allowed as an answer")
  }
  structure(
    class = c(
      "tutorial_question_answer", # new an improved name
      "tutorial_quiz_answer" # legacy. Want to remove
    ), 
    list(
      id = random_answer_id(),
      option = as.character(text),
      label = quiz_text(text),
      is_correct = isTRUE(correct),
      message = quiz_text(message)
    )
  )
}


format.tutorial_question_answer <- function(x, ..., spacing = "") {
  paste0(
    spacing,
    ifelse(x$is_correct, "X", "\u2714"), 
    ": ", 
    "\"", x$label, "\"",
    if (!is.null(x$message)) paste0("; \"", x$message, "\"")
  )
}

format.tutorial_question <- function(x, ..., spacing = "") {
  # x$label belongs to the knitr label
  paste0(
    spacing, "Question: \"", x$question, "\"\n",
    # all for a type vector
    spacing, "  type: ", paste0("\"", x$type, "\"", sep = "", collapse = ", "), "\n",
    spacing, "  allow retries: ", x$allow_retry, "\n",
    spacing, "  random order: ", x$random_answer_order, "\n",
    spacing, "  answers:\n",
    paste0(lapply(x$answers, format, spacing = paste0(spacing, "    ")), collapse = "\n"), "\n",
    spacing, "  messages:\n",
    spacing, "    correct: \"", x$messages$correct, "\"\n",
    spacing, "    incorrect: \"", x$messages$incorrect, "\"",
    if (x$allow_retry) paste0("\n", spacing, "    try again: \"", x$messages$try_again, "\"")
  )
}

format.tutorial_quiz <- function(x, ...) {
  paste0(
    "Quiz: \"", x$caption, "\"\n",
    "\n",
    paste0(lapply(x$questions, format, spacing = "  "), collapse = "\n\n")
  )
}

cat_format <- function(x, ...) {
  cat(format(x, ...), "\n")
}
print.tutorial_question <- cat_format
print.tutorial_question_answer <- cat_format
print.tutorial_quiz <- cat_format
