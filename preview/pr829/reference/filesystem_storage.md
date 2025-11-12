# Filesystem-based storage for tutor state data

Tutorial state storage handler that uses the filesystem as a backing
store. The directory will contain tutorial state data partitioned by
`user_id`, `tutorial_id`, and `tutorial_version` (in that order)

## Usage

``` r
filesystem_storage(dir, compress = TRUE)
```

## Arguments

- dir:

  Directory to store state data within

- compress:

  Should `.rds` files be compressed?

## Value

Storage handler suitable for `options(tutorial.storage = ...)`
