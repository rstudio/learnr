# Run a tutorial

Run a tutorial provided by an installed R package.

## Usage

``` r
run_tutorial(
  name = NULL,
  package = NULL,
  ...,
  shiny_args = NULL,
  clean = FALSE,
  as_rstudio_job = NULL
)
```

## Arguments

- name:

  Tutorial name (subdirectory within `tutorials/` directory of installed
  `package`). Alternatively, if `package` is not provided, `name` may be
  a path to a local tutorial R Markdown file or a local directory
  containing a learnr tutorial. If `package` is provided, `name` must be
  the tutorial name.

- package:

  Name of package. If `name` is a path to the local directory containing
  a learnr tutorial, then `package` should not be provided.

- ...:

  Unused. Included for future expansion and to ensure named arguments
  are used.

- shiny_args:

  Additional arguments to forward to
  [`shiny::runApp`](https://rdrr.io/pkg/shiny/man/runApp.html).

- clean:

  When `TRUE`, the shiny prerendered HTML files are removed and the
  tutorial is re-rendered prior to starting the tutorial.

- as_rstudio_job:

  Runs the tutorial in the background as an RStudio job. This is the
  default behavior when `run_tutorial()` detects that RStudio is
  available and can run jobs. Set to `FALSE` to disable and to run the
  tutorial in the current R session.

  When running as an RStudio job, `run_tutorial()` sets or overrides the
  `launch.browser` option for `shiny_args`. You can instead use the
  `shiny.launch.browser` global option in your current R session to set
  the default behavior when the tutorial is run. See [the shiny options
  documentation](https://rdrr.io/pkg/shiny/man/shinyOptions.html) for
  more information.

## Value

Starts a Shiny server running the learnr tutorial.

## See also

[`safe`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/safe.md) and
[`available_tutorials`](https:/pkgs.rstudio.com/learnr/v0.11.6/reference/available_tutorials.md)

## Examples

``` r
# display all "learnr" tutorials
available_tutorials("learnr")
#> Available tutorials:
#> * learnr
#>   - ex-data-basics    : "Data basics"
#>   - ex-data-filter    : "Filter observations"
#>   - ex-data-mutate    : "Create new variables"
#>   - ex-data-summarise : "Summarise Tables"
#>   - ex-setup-r        : "Set Up"
#>   - hello             : "Hello, Tutorial!"
#>   - polyglot          : "Multi-language exercises"
#>   - quiz_question     : "Tutorial Quiz Questions in `learnr`"
#>   - setup-chunks      : "Chained setup chunks"
#>   - slidy             : "Slidy demo"
#>   - sql-exercise      : "Interactive SQL Exercises" 

# run basic example within learnr
if (FALSE) { # \dontrun{
run_tutorial("hello", "learnr")
} # }
```
