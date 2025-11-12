# Text box question

Creates a tutorial question asking the student to enter text. The
default text input is appropriate for short or single-line text entry.
For longer text input, set the `rows` and/or `cols` argument to create a
larger text area.

When used with
[`answer()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md),
the student's submission must match the answer exactly, minus whitespace
trimming if enabled with `trim = TRUE`. For more complicated submission
evaluation, use
[`answer_fn()`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md)
to provide a function that checks the student's submission. For example,
you could provide a function that evaluates the user's submission using
[regular expressions](https://rdrr.io/r/base/regex.html).

## Usage

``` r
question_text(
  text,
  ...,
  correct = "Correct!",
  incorrect = "Incorrect",
  try_again = incorrect,
  allow_retry = FALSE,
  random_answer_order = FALSE,
  placeholder = "Enter answer here...",
  trim = TRUE,
  rows = NULL,
  cols = NULL,
  options = list()
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
  Answers with custom function checking

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

  **\[deprecated\]** Random answer order for text questions is
  automatically disabled to ensure that the submission is checked
  against each answer in the order they were provided by the author.

- placeholder:

  A character string giving the user a hint as to what can be entered
  into the control. Internet Explorer 8 and 9 do not support this
  option.

- trim:

  Logical to determine if whitespace before and after the answer should
  be removed. Defaults to `TRUE`.

- rows, cols:

  Defines the size of the text input area in terms of the number of rows
  or character columns visible to the user. If either `rows` or `cols`
  are provided, the quiz input will use
  [`shiny::textAreaInput()`](https://rdrr.io/pkg/shiny/man/textAreaInput.html)
  for the text input, otherwise the default input element is a
  single-line
  [`shiny::textInput()`](https://rdrr.io/pkg/shiny/man/textInput.html).

- options:

  Extra options to be stored in the question object. This is useful when
  using custom question types. See
  [`sortable::question_rank()`](https://rstudio.github.io/sortable/reference/question_rank.html)
  for an example question implementation that uses the `options`
  parameter.

## Value

Returns a learnr question of type `"learnr_text"`.

## See also

Other Interactive Questions:
[`question_checkbox()`](https://pkgs.rstudio.com/learnr/dev/reference/question_checkbox.md),
[`question_numeric()`](https://pkgs.rstudio.com/learnr/dev/reference/question_numeric.md),
[`question_radio()`](https://pkgs.rstudio.com/learnr/dev/reference/question_radio.md),
[`quiz()`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md)

## Examples

``` r
question_text(
  "Please enter the word 'C0rrect' below:",
  answer("correct", message = "Don't forget to capitalize"),
  answer("c0rrect", message = "Don't forget to capitalize"),
  answer("Correct", message = "Is it really an 'o'?"),
  answer("C0rrect ", message = "Make sure you do not have a trailing space"),
  answer("C0rrect", correct = TRUE),
  allow_retry = TRUE,
  trim = FALSE
)
#> Question: "Please enter the word ‘C0rrect’ below:"
#>   type: "learnr_text"
#>   allow_retry: TRUE
#>   random_answer_order: FALSE
#>   answers:
#>     X: "correct"; "Don’t forget to capitalize"
#>     X: "c0rrect"; "Don’t forget to capitalize"
#>     X: "Correct"; "Is it really an ‘o’?"
#>     X: "C0rrect"; "Make sure you do not have a trailing space"
#>     ✔: "C0rrect"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>     try_again: "Incorrect"
#>   Options:
#>     placeholder: "Enter answer here..."
#>     trim: FALSE 

# This question uses an answer_fn() to give a hint when we think the
# student is on the right track but hasn't found the value yet.
question_text(
  "What's the most popular programming interview question?",
  answer("fizz buzz", correct = TRUE, "That's right!"),
  answer_fn(function(value) {
    if (grepl("(fi|bu)zz", value)) {
      incorrect("You're on the right track!")
    }
  }, label = "fizz or buzz")
)
#> Question: "What’s the most popular programming interview question?"
#>   type: "learnr_text"
#>   allow_retry: FALSE
#>   random_answer_order: FALSE
#>   answers:
#>     ✔: "fizz buzz"; "That’s right!"
#>     ?: "fizz or buzz"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "Incorrect"
#>   Options:
#>     placeholder: "Enter answer here..."
#>     trim: TRUE 
```
