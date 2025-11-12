# Execute R code in a safe R environment

When rendering (or running) a document with R markdown, it inherits the
current R Global environment. This will produce unexpected behaviors,
such as poisoning the R Global environment with existing variables. By
rendering the document in a new, safe R environment, a *vanilla*,
rendered document is produced.

## Usage

``` r
safe(expr, ..., show = TRUE, env = safe_env())
```

## Arguments

- expr:

  expression that contains all the necessary library calls to execute.
  Expressions within callr do not inherit the existing, loaded
  libraries.

- ...:

  parameters passed to
  `callr::`[`r`](https://callr.r-lib.org/reference/r.html)

- show:

  Logical that determines if output should be displayed

- env:

  Environment to evaluate the document in

## Value

The result of `expr`.

## Details

The environment variable `LEARNR_INTERACTIVE` will be set to `"1"` or
`"0"` depending on if the calling session is interactive or not.

Using `safe` should only be necessary when locally deployed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Direct usage
safe(run_tutorial("hello", package = "learnr"))

# Programmatic usage
library(rlang)

expr <- quote(run_tutorial("hello", package = "learnr"))
safe(!!expr)

tutorial <- "hello"
safe(run_tutorial(!!tutorial, package = "learnr"))
} # }
```
