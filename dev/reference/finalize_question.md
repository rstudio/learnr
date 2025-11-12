# Finalize a question

Mark a question as finalized by adding a `question-final` class to the
HTML output at the top level, in addition to disabling all tags with
[`disable_all_tags()`](https://pkgs.rstudio.com/learnr/dev/reference/disable_all_tags.md).

## Usage

``` r
finalize_question(ele)
```

## Arguments

- ele:

  html tag element

## Value

An htmltools HTML object with appropriately appended classes such that a
tutorial question is marked as the final answer.

## Examples

``` r
# finalize the question UI
finalize_question(
  htmltools::div(
    class = "custom-question",
    htmltools::div("answer 1"),
    htmltools::div("answer 2")
  )
)
#> <div class="custom-question disabled question-final" disabled>
#>   <div class="disabled" disabled>answer 1</div>
#>   <div class="disabled" disabled>answer 2</div>
#> </div>
```
