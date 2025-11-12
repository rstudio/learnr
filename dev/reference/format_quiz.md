# Formatting and printing quizzes, questions, and answers

Notes:

- If custom question types are created, custom s3 formating methods may
  be implemented as well.

- Due to the shiny runtime of questions, a text representation of
  quizzes, questions, and answers will be presented.

## Usage

``` r
# S3 method for class 'tutorial_question_answer'
format(x, ..., spacing = "")

# S3 method for class 'tutorial_question'
format(x, ..., spacing = "")

# S3 method for class 'tutorial_quiz'
format(x, ...)

# S3 method for class 'tutorial_question'
print(x, ...)

# S3 method for class 'tutorial_question_answer'
print(x, ...)

# S3 method for class 'tutorial_quiz'
print(x, ...)
```

## Arguments

- x:

  object of interest

- ...:

  ignored

- spacing:

  Text to be placed at the beginning of each new line

## See also

[`quiz`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md),
[`question`](https://pkgs.rstudio.com/learnr/dev/reference/quiz.md),
[`answer`](https://pkgs.rstudio.com/learnr/dev/reference/answer.md)

## Examples

``` r
ex_question <- question("What number is the letter A in the alphabet?",
  answer("8"),
  answer("14"),
  answer("1", correct = TRUE),
  answer("23"),
  incorrect = "See [here](https://en.wikipedia.org/wiki/English_alphabet) and try again.",
  allow_retry = TRUE
)
cat(format(ex_question), "\n")
#> Question: "What number is the letter A in the alphabet?"
#>   type: "learnr_radio"
#>   allow_retry: TRUE
#>   random_answer_order: FALSE
#>   answers:
#>     X: "8"
#>     X: "14"
#>     ✔: "1"
#>     X: "23"
#>   messages:
#>     correct: "Correct!"
#>     incorrect: "See <a href="https://en.wikipedia.org/wiki/English_alphabet">here</a> and try again."
#>     try_again: "See <a href="https://en.wikipedia.org/wiki/English_alphabet">here</a> and try again." 
```
