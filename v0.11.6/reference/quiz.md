# Tutorial quiz questions

Add interactive quiz questions to a tutorial. Each quiz question is
executed within a shiny runtime to provide more flexibility in the types
of questions offered. There are four default types of quiz questions:

- `learnr_radio`:

  Radio button question. This question type will only allow for a single
  answer submission by the user. An answer must be marked for the user
  to submit their answer.

- `learnr_checkbox`:

  Check box question. This question type will allow for one or more
  answers to be submitted by the user. At least one answer must be
  marked for the user to submit their answer.

- `learnr_text`:

  Text box question. This question type will allow for free form text to
  be submitted by the user. At least one non-whitespace character must
  be added for the user to submit their answer.

- `learnr_numeric`:

  Numeric question. This question type will allow for a number to be
  submitted by the user. At least one number must be added for the user
  to submit their answer.

Note, the print behavior has changed as the runtime is now Shiny based.
If `question`s and `quiz`es are printed in the console, the S3 structure
and information will be displayed.

## Usage

``` r
quiz(..., caption = rlang::missing_arg())

question(
  text,
  ...,
  type = c("auto", "single", "multiple", "learnr_radio", "learnr_checkbox",
    "learnr_text", "learnr_numeric"),
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = NULL,
  message = NULL,
  post_message = NULL,
  loading = NULL,
  submit_button = rlang::missing_arg(),
  try_again_button = rlang::missing_arg(),
  allow_retry = FALSE,
  random_answer_order = FALSE,
  options = list()
)
```

## Arguments

- ...:

  One or more questions or answers

- caption:

  Optional quiz caption (defaults to "Quiz")

- text:

  Question or option text

- type:

  Type of quiz question. Typically this can be automatically determined
  based on the provided answers. Pass `"radio"` to indicate that even
  though multiple correct answers are specified that inputs which
  include only one correct answer are still correct. Pass `"checkbox"`
  to force the use of checkboxes (as opposed to radio buttons) even
  though only one correct answer was provided.

- correct:

  For `question`, text to print for a correct answer (defaults to
  "Correct!"). For `answer`, a boolean indicating whether this answer is
  correct.

- incorrect:

  Text to print for an incorrect answer (defaults to "Incorrect") when
  `allow_retry` is `FALSE`.

- try_again:

  Text to print for an incorrect answer when `allow_retry` is `TRUE`.
  Defaults to "Incorrect. Be sure to select every correct answer." for
  checkbox questions and "Incorrect" for non-checkbox questions.

- message:

  Additional message to display along with correct/incorrect feedback.
  This message is always displayed after a question submission.

- post_message:

  Additional message to display along with correct/incorrect feedback.
  If `allow_retry` is `TRUE`, this message will only be displayed after
  the correct submission. If `allow_retry` is `FALSE`, it will produce a
  second message alongside the `message` message value.

- loading:

  Loading text to display as a placeholder while the question is loaded.
  If not provided, generic "Loading..." or placeholder elements will be
  displayed.

- submit_button:

  Label for the submit button. Defaults to `"Submit Answer"`

- try_again_button:

  Label for the try again button. Defaults to `"Submit Answer"`

- allow_retry:

  Allow retry for incorrect answers. Defaults to `FALSE`.

- random_answer_order:

  Display answers in a random order.

- options:

  Extra options to be stored in the question object. This is useful when
  using custom question types. See
  [`sortable::question_rank()`](https://rstudio.github.io/sortable/reference/question_rank.html)
  for an example question implementation that uses the `options`
  parameter.

## Value

A learnr quiz, or collection of questions.

## See also

[`random_praise()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/random_praise.md),
[`random_encouragement()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/random_praise.md)

For more information and question type extension examples, please see
the help documentation for
[question_methods](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_methods.md)
and view the `question_type` tutorial:
`learnr::run_tutorial("question_type", "learnr")`.

Other Interactive Questions:
[`question_checkbox()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_checkbox.md),
[`question_numeric()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_numeric.md),
[`question_radio()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_radio.md),
[`question_text()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_text.md)

## Examples

``` r
quiz(
  question("What number is the letter A in the alphabet?",
    answer("8"),
    answer("14"),
    answer("1", correct = TRUE),
    answer("23"),
    incorrect = "See [here](https://en.wikipedia.org/wiki/English_alphabet) and try again.",
    allow_retry = TRUE
  ),

  question("Where are you right now? (select ALL that apply)",
    answer("Planet Earth", correct = TRUE),
    answer("Pluto"),
    answer("At a computing device", correct = TRUE),
    answer("In the Milky Way", correct = TRUE),
    incorrect = paste0("Incorrect. You're on Earth, ",
                       "in the Milky Way, at a computer.")
  )
)
#> Quiz: "<span data-i18n="text.quiz">Quiz</span>"
#> 
#>   Question: "What number is the letter A in the alphabet?"
#>     type: "learnr_radio"
#>     allow_retry: TRUE
#>     random_answer_order: FALSE
#>     answers:
#>       X: "8"
#>       X: "14"
#>       ✔: "1"
#>       X: "23"
#>     messages:
#>       correct: "Correct!"
#>       incorrect: "See <a href="https://en.wikipedia.org/wiki/English_alphabet">here</a> and try again."
#>       try_again: "See <a href="https://en.wikipedia.org/wiki/English_alphabet">here</a> and try again."
#> 
#>   Question: "Where are you right now? (select ALL that apply)"
#>     type: "learnr_checkbox"
#>     allow_retry: FALSE
#>     random_answer_order: FALSE
#>     answers:
#>       ✔: "Planet Earth"
#>       X: "Pluto"
#>       ✔: "At a computing device"
#>       ✔: "In the Milky Way"
#>     messages:
#>       correct: "Correct!"
#>       incorrect: "Incorrect. You’re on Earth, in the Milky Way, at a computer." 
```
