# Custom question methods

There are five methods used to define a custom question. Each S3 method
should correspond to the `type = TYPE` supplied to the question.

- `question_ui_initialize.TYPE(question, value, ...)`

  - Determines how the question is initially displayed to the users.
    This should return a shiny UI object that can be displayed using
    [shiny::renderUI](https://rdrr.io/pkg/shiny/man/renderUI.html). For
    example, in the case of `question_ui_initialize.radio`, it returns a
    [shiny::radioButtons](https://rdrr.io/pkg/shiny/man/radioButtons.html)
    object. This method will be re-executed if the question is attempted
    again.

- `question_ui_completed.TYPE(question, ...)`

  - Determines how the question is displayed after a submission. Just
    like `question_ui_initialize`, this method should return an shiny UI
    object that can be displayed using
    [shiny::renderUI](https://rdrr.io/pkg/shiny/man/renderUI.html).

- `question_is_valid.TYPE(question, value, ...)`

  - This method should return a boolean that determines if the input
    answer is valid. Depending on the value, this function enables and
    disables the submission button.

- `question_is_correct.TYPE(question, value, ...)`

  - This function should return the output of
    [correct](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md),
    [incorrect](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md),
    or
    [mark_as](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md).
    Each method allows for custom messages in addition to the
    determination of an answer being correct. See
    [correct](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md),
    [incorrect](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md),
    or
    [mark_as](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/mark_as_correct_incorrect.md)
    for more details.

- `question_ui_try_again <- function(question, value, ...)`

  - Determines how the question is displayed to the users while the "Try
    again" screen is displayed. Usually this function will disable
    inputs to the question, i.e. prevent the student from changing the
    answer options. Similar to `question_ui_initialize`, this should
    should return a shiny UI object that can be displayed using
    [shiny::renderUI](https://rdrr.io/pkg/shiny/man/renderUI.html).

## Usage

``` r
question_ui_initialize(question, value, ...)

question_ui_try_again(question, value, ...)

question_ui_completed(question, value, ...)

question_is_valid(question, value, ...)

question_is_correct(question, value, ...)

# Default S3 method
question_ui_initialize(question, value, ...)

# Default S3 method
question_ui_try_again(question, value, ...)

# Default S3 method
question_ui_completed(question, value, ...)

# Default S3 method
question_is_valid(question, value, ...)

# Default S3 method
question_is_correct(question, value, ...)
```

## Arguments

- question:

  [question](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/quiz.md)
  object used

- value:

  user input value

- ...:

  future parameter expansion and custom arguments to be used in
  dispatched s3 methods.

## Value

learnr question objects, UI elements, results or server methods.

## See also

For more information and question type extension examples, please see
the **Custom Question Types** section of the `quiz_question` tutorial:
`learnr::run_tutorial("quiz_question", "learnr")`.

## Examples

``` r
q <- question(
  "Which package helps you teach programming skills?",
  answer("dplyr"),
  answer("learnr", correct = TRUE),
  answer("base")
)
question_is_correct(q, "dplyr")
#> $correct
#> [1] FALSE
#> 
#> $messages
#> NULL
#> 
#> attr(,"class")
#> [1] "learnr_mark_as"
question_is_correct(q, "learnr")
#> $correct
#> [1] TRUE
#> 
#> $messages
#> NULL
#> 
#> attr(,"class")
#> [1] "learnr_mark_as"
```
