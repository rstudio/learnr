# Number question

Creates a tutorial question asking the student to submit a number.

## Usage

``` r
question_numeric(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  value = NULL,
  min = NA,
  max = NA,
  step = NA,
  options = list(),
  tolerance = 1.5e-08
)
```

## Arguments

- text:

  Question or option text

- ...:

  Answers created with
  [`answer()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md)
  or
  [`answer_fn()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md),
  or extra parameters passed onto
  [`question()`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md).

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

- value:

  Initial value.

- min:

  Minimum allowed value

- max:

  Maximum allowed value

- step:

  Interval to use when stepping between min and max

- options:

  Extra options to be stored in the question object. This is useful when
  using custom question types. See
  [`sortable::question_rank()`](https://rstudio.github.io/sortable/reference/question_rank.html)
  for an example question implementation that uses the `options`
  parameter.

- tolerance:

  Submitted values within an absolute difference less than or equal to
  `tolerance` will be considered equal to the answer value. Note that
  this tolerance is for all
  [`answer()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md)
  values. For more specific answer value grading, use
  [`answer_fn()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md)
  to provide your own evaluation code.

## Value

Returns a learnr question of type `"learnr_numeric"`.

## See also

Other Interactive Questions:
[`question_checkbox()`](https://pkgs.rstudio.com/learnr/dev/reference/question_checkbox.md),
[`question_radio()`](https://pkgs.rstudio.com/learnr/dev/reference/question_radio.md),
[`question_text()`](https://pkgs.rstudio.com/learnr/dev/reference/question_text.md),
[`quiz()`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md)

## Examples

``` r
question_numeric(
  "What is pi rounded to 2 digits?",
  answer(3, message = "Don't forget to use the digits argument"),
  answer(3.1, message = "Too few digits"),
  answer(3.142, message = "Too many digits"),
  answer(3.14, correct = TRUE),
  allow_retry = TRUE,
  min = 3,
  max = 4,
  step = 0.01
)
#> Question: "What is pi rounded to 2 digits?"
#>   type: "learnr_numeric"
#>   allow_retry: TRUE
#>   random_answer_order: FALSE
#>   answers:
#>     X: "3"; "Don’t forget to use the digits argument"
#>     X: "3.1"; "Too few digits"
#>     X: "3.142"; "Too many digits"
#>     ✔: "3.14"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>     try_again: "Incorrect"
#>   Options:
#>     min: 3
#>     max: 4
#>     step: 0.01
#>     tolerance: 1.5e-08 

question_numeric(
  "Can you think of an even number?",
  answer_fn(function(value) {
    if (value %% 2 == 0) {
      correct("even")
    } else if (value %% 2 == 1) {
      incorrect("odd")
    }
  }, label = "Is the number even?"),
  step = 1
)
#> Question: "Can you think of an even number?"
#>   type: "learnr_numeric"
#>   allow_retry: FALSE
#>   random_answer_order: FALSE
#>   answers:
#>     ?: "Is the number even?"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>   Options:
#>     min: NA
#>     max: NA
#>     step: 1
#>     tolerance: 1.5e-08 
```
