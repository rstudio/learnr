# Initialize tutorial R Markdown extensions

One time initialization of R Markdown extensions required by the learnr
package. This function is typically called automatically as a result of
using exercises or questions.

## Usage

``` r
initialize_tutorial()
```

## Value

If not previously run, initializes knitr hooks and provides the required
[`rmarkdown::shiny_prerendered_chunk()`](https://pkgs.rstudio.com/rmarkdown/reference/shiny_prerendered_chunk.html)s
to initialize learnr.
