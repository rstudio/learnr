# Add phrases to the bank of random phrases

Augment the random phrases available in
[`random_praise()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/random_praise.md)
and
[`random_encouragement()`](https:/pkgs.rstudio.com/learnr/preview/pr829/reference/random_praise.md)
with phrases of your own. Note that these phrases are added to the
existing phrases, rather than overwriting them.

## Usage

``` r
random_phrases_add(language = "en", praise = NULL, encouragement = NULL)
```

## Arguments

- language:

  The language of the phrases to be added.

- praise, encouragement:

  A vector of praising or encouraging phrases, including final
  punctuation.

## Value

Returns the previous custom phrases invisibly when called in the global
setup chunk or interactively. Otherwise, it returns a shiny pre-
rendered chunk.

## Usage in learnr tutorials

To add random phrases in a learnr tutorial, you can either include one
or more calls to `random_phrases_add()` in your global setup chunk:

    ```{r setup, include = FALSE}`r ''`
    library(learnr)
    random_phrases_add(
      language = "en",
      praise = "Great work!",
      encouragement = "I believe in you."
    )
    ```

Alternatively, you can call `random_phrases_add()` in a separate,
standard R chunk (with `echo = FALSE`):

    ```{r setup-phrases, echo = FALSE}`r ''`
    random_phrases_add(
      language = "en",
      praise = c("Great work!", "You're awesome!"),
      encouragement = c("I believe in you.", "Yes we can!")
    )
    ```

## Examples

``` r
random_phrases_add("demo", praise = "Great!", encouragement = "Try again.")
random_praise(language = "demo")
#> [1] "Great!"
random_encouragement(language = "demo")
#> [1] "Try again."

```
