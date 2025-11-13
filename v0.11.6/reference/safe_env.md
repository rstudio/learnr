# Safe R CMD environment

By default,
`callr::`[`rcmd_safe_env`](https://callr.r-lib.org/reference/rcmd_safe_env.html)
suppresses the ability to open a browser window. This is the default
execution environment within
`callr::`[`r`](https://callr.r-lib.org/reference/r.html). However,
opening a browser is expected behavior within the learnr package and
should not be suppressed.

## Usage

``` r
safe_env()
```

## Value

A list of envvars, modified from
[`callr::rcmd_safe_env()`](https://callr.r-lib.org/reference/rcmd_safe_env.html).

## Examples

``` r
safe_env()
#>             CYGWIN            R_TESTS        R_PDFVIEWER 
#> "nodosfilewarning"                 ""            "false" 
```
