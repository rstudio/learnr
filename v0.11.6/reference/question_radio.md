# Radio question

Creates a radio button tutorial quiz question. The student can select
only one radio button before submitting their answer. Note: Multiple
correct answers are allowed.

## Usage

``` r
question_radio(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  random_answer_order = FALSE
)
```

## Arguments

- text:

  Question or option text

- ...:

  Answers created with
  [`answer()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md)
  or extra parameters passed onto
  [`question()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md).
  Function answers are ignored for radio questions because the user is
  required to select a single answer.

- correct:

  For `question`, text to print for a correct answer (defaults to
  "Correct!"). For `answer`, a boolean indicating whether this answer is
  correct.

- incorrect:

  Text to print for an incorrect answer (defaults to "Incorrect") when
  `allow_retry` is `FALSE`.

- try_again:

  Text to print for an incorrect answer (defaults to "Incorrect") when
  `allow_retry` is `TRUE`.

- allow_retry:

  Allow retry for incorrect answers. Defaults to `FALSE`.

- random_answer_order:

  Display answers in a random order.

## Value

Returns a learnr question of type `"learnr_radio"`.

## See also

Other Interactive Questions:
[`question_checkbox()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_checkbox.md),
[`question_numeric()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_numeric.md),
[`question_text()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_text.md),
[`quiz()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md)

## Examples

``` r
question_radio(
  "Pick the letter B",
  answer("A"),
  answer("B", correct = TRUE),
  answer("C"),
  answer("D"),
  allow_retry = TRUE,
  random_answer_order = TRUE
)
#> Question: "Pick the letter B"
#>   type: "learnr_radio"
#>   allow_retry: TRUE
#>   random_answer_order: TRUE
#>   answers:
#>     X: "A"
#>     ✔: "B"
#>     X: "C"
#>     X: "D"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>     try_again: "Incorrect" 
```
