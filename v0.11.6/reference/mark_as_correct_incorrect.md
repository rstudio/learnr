# Mark submission as correct or incorrect

Helper method to communicate that the user's submission was correct or
incorrect. These functions were originally designed for developers to
create
[`question_is_correct()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_methods.md)
methods for custom question types, but they can also be called inside
the functions created by
[`answer_fn()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md)
to dynamically determine the result and message provided to the user.

## Usage

``` r
correct(messages = NULL)

incorrect(messages = NULL)

mark_as(correct, messages = NULL)
```

## Arguments

- messages:

  A vector of messages to be displayed. The type of message will be
  determined by the `correct` value. Note that markdown messages are not
  rendered into HTML, but you may provide HTML using
  [`htmltools::HTML()`](https://rstudio.github.io/htmltools/reference/HTML.html)
  or
  [htmltools::tags](https://rstudio.github.io/htmltools/reference/builder.html).

- correct:

  Logical: is the question answer is correct

## Value

Returns a list with class `learnr_mark_as` to be returned from the
[`question_is_correct()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/question_methods.md)
method for the learnr question type.

## See also

[`answer_fn()`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/answer.md)

## Examples

``` r
# Radio button question implementation of `question_is_correct`
question_is_correct.radio <- function(question, value, ...) {
  for (ans in question$answers) {
    if (as.character(ans$option) == value) {
      return(mark_as(ans$correct, ans$message))
    }
  }
  mark_as(FALSE, NULL)
}
```
