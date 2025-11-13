# List available tutorials

List the tutorials that are currently available via installed R
packages. Or list the specific tutorials that are contained within a
given R package.

## Usage

``` r
available_tutorials(package = NULL)
```

## Arguments

- package:

  Name of package

## Value

`available_tutorials()` returns a `data.frame` containing "package",
"name", "title", "description", "package_dependencies", "private", and
"yaml_front_matter".

## Examples

``` r
available_tutorials(package = "learnr")
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
```
