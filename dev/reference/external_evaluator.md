# External execution evaluator

[Lifecycle:
experimental](https://lifecycle.r-lib.org/articles/stages.html)

## Usage

``` r
external_evaluator(
  endpoint = getOption("tutorial.external.host",
    Sys.getenv("TUTORIAL_EXTERNAL_EVALUATOR_HOST", NA)),
  max_curl_conns = 50
)
```

## Arguments

- endpoint:

  The HTTP(S) endpoint to POST the exercises to

- max_curl_conns:

  The maximum number of simultaneous HTTP requests to the endpoint.

## Value

A function that takes an expression (`expr`), `timelimit`, `exercise`
and `session`.
