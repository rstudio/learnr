# Observe the user's progress in the tutorial

As a student progresses through a learnr tutorial, their progress is
stored in a Shiny reactive values list for their session (see
[`shiny::reactiveValues()`](https://rdrr.io/pkg/shiny/man/reactiveValues.html)).
Without arguments, `get_tutorial_state()` returns the full
reactiveValues object that can be converted to a conventional list with
[`shiny::reactiveValuesToList()`](https://rdrr.io/pkg/shiny/man/reactiveValuesToList.html).
If the `label` argument is provided, the state of an individual question
or exercise with that label is returned.

Calling `get_tutorial_state()` introduces a reactive dependency on the
state of returned questions or exercises unless called within
`isolate()`. Note that `get_tutorial_state()` will only work for the
tutorial author and must be used in a reactive context, i.e. within
[`shiny::observe()`](https://rdrr.io/pkg/shiny/man/observe.html),
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html),
or [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html).
Any logic observing the user's tutorial state must be written inside a
`context="server"` chunk in the tutorial's R Markdown source.

## Usage

``` r
get_tutorial_state(label = NULL, session = getDefaultReactiveDomain())
```

## Arguments

- label:

  A length-1 character label of the exercise or question.

- session:

  The `session` object passed to function given to `shinyServer.`
  Default is
  [`shiny::getDefaultReactiveDomain()`](https://rdrr.io/pkg/shiny/man/domains.html).

## Value

A reactiveValues object or a single reactive value (if `label` is
provided). The names of the full reactiveValues object correspond to the
label of the question or exercise. Each item contains the following
entries:

- `type`: One of `"question"` or `"exercise"`.

- `answer`: A character vector containing the user's submitted
  answer(s).

- `correct`: A logical indicating whether the user's answer was correct,
  or a logical `NA` if the submission was not checked for correctness.

- `timestamp`: The time at which the user's submission was completed, as
  a character string in UTC, formatted as `"%F %H:%M:%OS3 %Z"`.

## See also

[`get_tutorial_info()`](https://pkgs.rstudio.com/learnr/dev/reference/get_tutorial_info.md)
