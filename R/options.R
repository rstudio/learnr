
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
#' @param exercise.alert_class,exercise.gradethis_info_color,exercise.gradethis_success_color,exercise.gradethis_warning_color,exercise.gradethis_danger_color Slug for the CSS class for `{learnr}` and `{gradethis}` message.
#' It can be one of `red`, `orange`, `purple`, `blue`, `violet`, `yellow`, `pink`, `green`,
#' or `grey`. You can also implement your own CSS rule, in that case you need to define a
#' class that starts with `alert-` (for example `alert-rainbow`).
#' @param exercise.feedback_show Should the `{learnr}` feedback be shown?
#' @param exercise.code_show Should `{learnr}` output code be shown?
#' @param exercise.execution_error_message What message should `{learnr}` print on error?
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
  exercise.alert_class = "red",
  exercise.feedback_show = TRUE,
  exercise.code_show = TRUE,
  exercise.execution_error_message = NULL,
  exercise.gradethis_success_color = NULL,
  exercise.gradethis_info_color = NULL,
  exercise.gradethis_warning_color = NULL,
  exercise.gradethis_danger_color = NULL,
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
  # browser()
  # eval(parse(text = sprintf(set_option_code, "exercise.cap")))
  # eval(parse(text = sprintf(set_option_code, "exercise.eval")))
  # eval(parse(text = sprintf(set_option_code, "exercise.timelimit")))
  # eval(parse(text = sprintf(set_option_code, "exercise.lines")))
  # eval(parse(text = sprintf(set_option_code, "exercise.checker")))
  # eval(parse(text = sprintf(set_option_code, "exercise.error.check.code")))
  # eval(parse(text = sprintf(set_option_code, "exercise.completion")))
  # eval(parse(text = sprintf(set_option_code, "exercise.diagnostics")))
  # eval(parse(text = sprintf(set_option_code, "exercise.startover")))
  # eval(parse(text = sprintf(set_option_code, "exercise.alert_color")))
  # eval(parse(text = sprintf(set_option_code, "exercise.gradethis_success_color")))
  # eval(parse(text = sprintf(set_option_code, "exercise.gradethis_info_color")))
  # eval(parse(text = sprintf(set_option_code, "exercise.gradethis_warning_color")))
  # eval(parse(text = sprintf(set_option_code, "exercise.gradethis_danger_color")))
}
