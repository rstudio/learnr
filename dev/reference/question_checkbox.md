# Checkbox question

Creates a checkbox group tutorial quiz question. The student may select
one or more checkboxes before submitting their answer.

## Usage

``` r
question_checkbox(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = "Incorrect. Be sure to select every correct answer.",
  allow_retry = FALSE,
  random_answer_order = FALSE
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
  Function answers do not appear in the checklist, but are checked first
  in the order they are specified.

- correct:

  For `question`, text to print for a correct answer (defaults to
  "Correct!"). For `answer`, a boolean indicating whether this answer is
  correct.

- incorrect:

  Text to print for an incorrect answer (defaults to "Incorrect") when
  `allow_retry` is `FALSE`.

- try_again:

  Text to print for an incorrect answer (defaults to "Incorrect. Be sure
  to select every correct answer.") when `allow_retry` is `TRUE`.

- allow_retry:

  Allow retry for incorrect answers. Defaults to `FALSE`.

- random_answer_order:

  Display answers in a random order.

## Value

Returns a learnr question of type `"learnr_checkbox"`.

## See also

Other Interactive Questions:
[`question_numeric()`](https://pkgs.rstudio.com/learnr/dev/reference/question_numeric.md),
[`question_radio()`](https://pkgs.rstudio.com/learnr/dev/reference/question_radio.md),
[`question_text()`](https://pkgs.rstudio.com/learnr/dev/reference/question_text.md),
[`quiz()`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md)

## Examples

``` r
question_checkbox(
  "Select all the toppings that belong on a Margherita Pizza:",
  answer("tomato", correct = TRUE),
  answer("mozzarella", correct = TRUE),
  answer("basil", correct = TRUE),
  answer("extra virgin olive oil", correct = TRUE),
  answer("pepperoni", message = "Great topping! ... just not on a Margherita Pizza"),
  answer("onions"),
  answer("bacon"),
  answer("spinach"),
  random_answer_order = TRUE,
  allow_retry = TRUE,
  try_again = "Be sure to select all four toppings!"
)
#> Question: "Select all the toppings that belong on a Margherita Pizza:"
#>   type: "learnr_checkbox"
#>   allow_retry: TRUE
#>   random_answer_order: TRUE
#>   answers:
#>     ✔: "tomato"
#>     ✔: "mozzarella"
#>     ✔: "basil"
#>     ✔: "extra virgin olive oil"
#>     X: "pepperoni"; "Great topping! … just not on a Margherita Pizza"
#>     X: "onions"
#>     X: "bacon"
#>     X: "spinach"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>     try_again: "Be sure to select all four toppings!" 

# Set up a question where there's no wrong answer. The answer options are
# always shuffled, but the answer_fn() answer is always evaluated first.
question_checkbox(
  "Which of the tidyverse packages is your favorite?",
  answer("dplyr"),
  answer("tidyr"),
  answer("ggplot2"),
  answer("tibble"),
  answer("purrr"),
  answer("stringr"),
  answer("forcats"),
  answer("readr"),
  answer_fn(function(value) {
    if (length(value) == 1) {
      correct(paste(value, "is my favorite tidyverse package, too!"))
    } else {
      correct("Yeah, I can't pick just one favorite package either.")
    }
  }),
  random_answer_order = TRUE
)
#> Question: "Which of the tidyverse packages is your favorite?"
#>   type: "learnr_checkbox"
#>   allow_retry: FALSE
#>   random_answer_order: TRUE
#>   answers:
#>     X: "dplyr"
#>     X: "tidyr"
#>     X: "ggplot2"
#>     X: "tibble"
#>     X: "purrr"
#>     X: "stringr"
#>     X: "forcats"
#>     X: "readr"
#>     ?: ""
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect" 
```
