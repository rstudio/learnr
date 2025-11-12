# List tutorial dependencies

List the R packages required to run a particular tutorial.

## Usage

``` r
tutorial_package_dependencies(name = NULL, package = NULL)
```

## Arguments

- name:

  The tutorial name. If `name` is `NULL`, then all tutorials within
  `package` will be searched.

- package:

  The R package providing the tutorial. If `package` is `NULL`, then all
  tutorials will be searched.

## Value

A character vector of package names that are required for execution.

## Examples

``` r
tutorial_package_dependencies(package = "learnr")
#>  [1] "DBI"          "Lahman"       "RSQLite"      "dygraphs"    
#>  [5] "gradethis"    "knitr"        "learnr"       "nycflights13"
#>  [9] "rlang"        "rmarkdown"    "shiny"        "sortable"    
#> [13] "tidyverse"   
```
