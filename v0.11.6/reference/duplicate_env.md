# Create a duplicate of an environment

Copy all items from the environment to a new environment. By default,
the new environment will share the same parent environment.

## Usage

``` r
duplicate_env(envir, parent = parent.env(envir))
```

## Arguments

- envir:

  environment to duplicate

- parent:

  parent environment to set for the new environment. Defaults to the
  parent environment of `envir`.

## Value

A duplicated copy of `envir` whose parent env is `parent`.

## Examples

``` r
# Make a new environment with the object 'key'
envir <- new.env()
envir$key <- "value"
"key" %in% ls() # FALSE
#> [1] FALSE
"key" %in% ls(envir = envir) # TRUE
#> [1] TRUE

# Duplicate the envir and show it contains 'key'
new_envir <- duplicate_env(envir)
"key" %in% ls(envir = new_envir) # TRUE
#> [1] TRUE
```
