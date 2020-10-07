
#' Set tutorial options
#'
#' Set various tutorial options that control the display and evaluation of
#' exercises.
#'
#' @param exercise.cap Caption for exercise chunk (defaults to the engine's icon or the combination of the engine and \code{" code"}).
#' @param exercise.eval Whether to pre-evaluate the exercise so the reader can
#'   see some default output (defaults to \code{FALSE}).
#' @param exercise.timelimit Number of seconds to limit execution time to
#'   (defaults to \code{30}).
#' @param exercise.lines Lines of code for exercise editor (defaults to the
#'   number of lines in the code chunk).
#' @param exercise.checker Function used to check exercise answers
#'   (e.g., `gradethis::grade_learnr()`).
#' @param exercise.error.check.code A string containing R code to use for checking
#'   code when an exercise evaluation error occurs (e.g., `"gradethis::grade_code()"`).
#' @param exercise.completion Use code completion in exercise editors.
#' @param exercise.diagnostics Show diagnostics in exercise editors.
#' @param exercise.startover Show "Start Over" button on exercise.
#' @param exercise.alert_class,exercise.info_class,exercise.success_class,exercise.warning_class,exercise.danger_class The CSS class for `{learnr}` and `{gradethis}` message.
#' It can be one of `alert-success`, `alert-info`, `alert-warning`, `alert-danger`,
#' `alert-red`, `alert-orange`, `alert-purple`, `alert-blue`, `alert-violet`,
#' `alert-yellow`, `alert-pink`, `alert-green`, or `alert-grey`.
#' You can also use your own CSS class.
# #' @param exercise.execution_error_message What message should `{learnr}` print on error?
#' @param exercise.submitted_feedback Should submitted exercise feedback be shown?
#' @param exercise.submitted_output Should submitted exercise output be shown?
#'
#' @export
tutorial_options <- function(
  exercise.cap = NULL,
  exercise.eval = FALSE,
  exercise.timelimit = 30,
  exercise.lines = NULL,
  exercise.checker = NULL,
  exercise.error.check.code = NULL,
  exercise.completion = TRUE,
  exercise.diagnostics = TRUE,
  exercise.startover = TRUE,
  exercise.alert_class = "alert-red",
  exercise.success_class = "alert-success",
  exercise.info_class = "alert-info",
  exercise.warning_class = "alert-warning",
  exercise.danger_class = "alert-danger",
  exercise.submitted_feedback = TRUE,
  exercise.submitted_output = TRUE
)
{
  # string to evalute for setting chunk options  %1$s
  set_option_code <- 'if (!missing(%1$s)) knitr::opts_chunk$set(%1$s = %1$s)'

  # set options as required
  for (i in names(formals())){
    eval(parse(text = sprintf(set_option_code, i)))
  }
}
