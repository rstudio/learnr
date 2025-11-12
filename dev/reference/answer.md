# Question answer options

Create options for users when used in
[`question_checkbox()`](https://pkgs.rstudio.com/learnr/dev/reference/question_checkbox.md)
and
[`question_radio()`](https://pkgs.rstudio.com/learnr/dev/reference/question_radio.md)
learnr questions. For
[`question_text()`](https://pkgs.rstudio.com/learnr/dev/reference/question_text.md)
and
[`question_numeric()`](https://pkgs.rstudio.com/learnr/dev/reference/question_numeric.md),
the individual answers aren't directly presented to students, but their
values can be used in determining if the student submitted the correct
answer. For flexible feedback from checkbox, text, and numeric
questions, `answer_fn()` can be used to provide a function that
evaluates the student's submission and returns a custom result.

## Usage

``` r
answer(text, correct = FALSE, message = NULL, label = text)

answer_fn(fn, label = NULL)
```

## Arguments

- text:

  The answer text or value; for selection-type questions this value is
  shown to the user.

- correct:

  Logical value indicating whether the `answer()` corresponds to a
  correct or incorrect option.

- message:

  A custom message shown when this answer is selected and when the
  overall question result matches the state of this answer. For example,
  the `message` of a correct solution is not shown when the entire
  submission is incorrect, but *will* be shown when the user both picks
  this answer option and the question is *correct*.

- label:

  The label shown when the option is presented to the user.

- fn:

  A function used to evaluate the submitted answer. The function is
  called with the student's submitted value as the first argument, so
  the function should take at least one argument where the user's value
  will be passed to the first argument. Inline purrr-style lambda
  functions are allowed, see
  [`rlang::as_function()`](https://rlang.r-lib.org/reference/as_function.html)
  for complete details on the syntax.

  In the body of the function, you can perform arbitrary calculations to
  decide if the submitted answer is or is not correct and to compose the
  message presented to the user. To signal a final answer, call
  [`mark_as()`](https://pkgs.rstudio.com/learnr/dev/reference/mark_as_correct_incorrect.md)
  or its helper functions
  [`correct()`](https://pkgs.rstudio.com/learnr/dev/reference/mark_as_correct_incorrect.md)
  or
  [`incorrect()`](https://pkgs.rstudio.com/learnr/dev/reference/mark_as_correct_incorrect.md).
  All other return values are ignored; e.g. by returning `NULL` you may
  yield the submission evaluation to other `answer()` or `answer_fn()`
  options for the question.

## Value

Returns a list with the `"tutorial_question_answer"` class.

## Functions

- `answer()`: Create an answer option

- `answer_fn()`: Evaluate the student's submission to determine
  correctness and to return feedback.

## Examples

``` r
answer(32, correct = FALSE)
#> X: "32" 
answer(42, correct = TRUE, message = "The meaning of life.")
#> ✔: "42"; "The meaning of life." 
```
