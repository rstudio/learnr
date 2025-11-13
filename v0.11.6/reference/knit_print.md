# Knitr quiz print methods

`knitr::`[`knit_print`](https://rdrr.io/pkg/knitr/man/knit_print.html)
methods for
[`question`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md)
and [`quiz`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/quiz.md)

## Usage

``` r
# S3 method for class 'tutorial_question'
knit_print(x, ...)

# S3 method for class 'tutorial_quiz'
knit_print(x, ...)
```

## Arguments

- x:

  An R object to be printed

- ...:

  Additional arguments passed to the S3 method. Currently ignored,
  except two optional arguments `options` and `inline`; see the
  references below.
