# Random praise and encouragement

Random praises and encouragements sayings to compliment your question
and quiz experience.

## Usage

``` r
random_praise(language = NULL)

random_encouragement(language = NULL)
```

## Arguments

- language:

  The language for the random phrase. The currently supported languages
  include: `en`, `es`, `pt`, `pl`, `tr`, `de`, `emo`, and `testing`
  (static phrases).

## Value

Character string with a random saying

## Examples

``` r
random_praise()
#> [1] "Awesome!"
random_praise()
#> [1] "Nice job!"

random_encouragement()
#> [1] "Let's try it again."
random_encouragement()
#> [1] "Don't give up now, try it one more time."
```
