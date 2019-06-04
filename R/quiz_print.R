#' Formatting and printing quizes, questions, and answers
#'
#' Notes:
#' \itemize{
#'   \item If custom question types are created, custom s3 formating methods may be implemented as well.
#'   \item Due to the shiny runtime of questions, a text representation of quizes, questions, and answers will be presented.
#' }
#'
#' @param x object of interest
#' @param ... ignored
#' @param spacing Text to be placed at the beginning of each new line
#' @seealso \code{\link{quiz}}, \code{\link{question}}, \code{\link{answer}}
#' @export
#' @rdname format_quiz
#' @examples
#' ex_question <- question("What number is the letter A in the alphabet?",
#'   answer("8"),
#'   answer("14"),
#'   answer("1", correct = TRUE),
#'   answer("23"),
#'   incorrect = "See [here](https://en.wikipedia.org/wiki/English_alphabet) and try again.",
#'   allow_retry = TRUE
#' )
#' cat(format(ex_question), "\n")
format.tutorial_question_answer <- function(x, ..., spacing = "") {
  paste0(
    spacing,
    ifelse(x$is_correct, "\u2714", "X"),
    ": ",
    "\"", x$label, "\"",
    if (!is.null(x$message)) paste0("; \"", x$message, "\"")
  )
}
#' @export
#' @rdname format_quiz
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
#' @export
#' @rdname format_quiz
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
#' @export
#' @rdname format_quiz
print.tutorial_question <- cat_format
#' @export
#' @rdname format_quiz
print.tutorial_question_answer <- cat_format
#' @export
#' @rdname format_quiz
print.tutorial_quiz <- cat_format
