# An Exercise Checker for Debugging

An exercise checker for debugging that renders all of the expected
arguments of the `exercise.checker` option into HTML. Additionally, this
function is used in testing of `evaluate_exercise()`.

## Usage

``` r
debug_exercise_checker(
  label,
  user_code,
  solution_code,
  check_code,
  envir_result,
  evaluate_result,
  envir_prep,
  last_value,
  engine,
  ...
)
```

## Arguments

- label:

  Exercise label

- user_code:

  Submitted user code

- solution_code:

  The code in the `*-solution` chunk

- check_code:

  The checking code that originates from the `*-check` chunk, the
  `*-code-check` chunk, or the `*-error-check` chunk.

- evaluate_result:

  The return value from
  [`evaluate::evaluate()`](https://pkgs.rstudio.com/learnr/dev/reference/evaluate.r-lib.org/reference/evaluate.md),
  called on `user_code`

- envir_prep, envir_result:

  The environment before running user code (`envir_prep`) and the
  environment just after running the user's code (`envir_result`).

- last_value:

  The last value after evaluating `user_code`

- engine:

  The engine of the exercise chunk

- ...:

  Not used (future compatibility)

## Value

Feedback for use in exercise debugging.
