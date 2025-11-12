# Set tutorial options

Set various tutorial options that control the display and evaluation of
exercises.

## Usage

``` r
tutorial_options(
  exercise.cap = NULL,
  exercise.eval = FALSE,
  exercise.timelimit = 30,
  exercise.lines = NULL,
  exercise.pipe = NULL,
  exercise.blanks = NULL,
  exercise.checker = NULL,
  exercise.error.check.code = NULL,
  exercise.completion = TRUE,
  exercise.diagnostics = TRUE,
  exercise.startover = TRUE,
  exercise.reveal_solution = TRUE
)
```

## Arguments

- exercise.cap:

  Caption for exercise chunk (defaults to the engine's icon or the
  combination of the engine and `" code"`).

- exercise.eval:

  Whether to pre-evaluate the exercise so the reader can see some
  default output (defaults to `FALSE`).

- exercise.timelimit:

  Number of seconds to limit execution time to (defaults to `30`).

- exercise.lines:

  Lines of code for exercise editor (defaults to the number of lines in
  the code chunk).

- exercise.pipe:

  The characters to enter when the user presses the "Insert Pipe"
  keyboard shortcut in the exercise editor (`Ctrl/Cmd + Shift + M`).
  This can be set at the tutorial level or for an individual exercise.
  If `NULL` (default), the base R pipe (`|>`) is used when the tutorial
  is rendered in R \>= 4.1.0, otherwise the magrittr pipe (`%>%`) is
  used.

- exercise.blanks:

  A regular expression to be used to identify blanks in submitted code
  that the user should fill in. If `TRUE` (default), blanks are three or
  more underscores in a row. If `FALSE`, blank checking is not
  performed.

- exercise.checker:

  Function used to check exercise answers (e.g.,
  `gradethis::grade_learnr()`).

- exercise.error.check.code:

  A string containing R code to use for checking code when an exercise
  evaluation error occurs (e.g., `"gradethis::grade_code()"`).

- exercise.completion:

  Use code completion in exercise editors.

- exercise.diagnostics:

  Show diagnostics in exercise editors.

- exercise.startover:

  Show "Start Over" button on exercise.

- exercise.reveal_solution:

  Whether to reveal the exercise solution if a solution chunk is
  provided.

## Value

Nothing. Invisibly sets
[knitr::opts_chunk](https://rdrr.io/pkg/knitr/man/opts_chunk.html)
settings.

## Examples

``` r
if (interactive()) {
  tutorial_options(exercise.eval = TRUE, exercise.timelimt = 10)
}
```
