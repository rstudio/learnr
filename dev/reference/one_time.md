# Wrap an expression that will be executed one time in an event handler

This wraps an expression so that it will be executed one time for a
tutorial, based on some condition. The first time the condition is true,
the expression will be executed; after that, the expression will not be
evaluated again.

The execution state is stored so that if the expression is executed,
then the user quits the tutorial and then returns to it, the expression
will not be executed a second time.

A common use for `one_time` is to execute an expression when a section
is viewed for the first time.

## Usage

``` r
one_time(session, cond, expr, label = deparse(substitute(cond)))
```

## Arguments

- session:

  A Shiny session object.

- cond:

  A condition that is used as a filter. The first time the condition
  evaluates to true, `expr` will be evaluated; after that, `expr` will
  not be evaluated again.

- expr:

  An expression that will be evaluated once, the first time that `cond`
  is true.

- label:

  A unique identifier. This is used as an ID for the condition and
  expression; if two calls to `one_time()` uses the same label, there
  will be an ID collision and only one of them will execute. By default,
  `cond` is deparsed and used as the label.

## Value

The result of evaluating `expr` (`one_time()` is intended to be called
within an event handler).

## Examples

``` r
if (FALSE) { # \dontrun{
# This goes in a {r context="server-start"} chunk

# The expression with message() will be executed the first time the user
# sees the section with ID "section-exercise-with-hint".
event_register_handler("section_viewed",
  function(session, event, data) {
    one_time(
      session,
      data$sectionId == "section-exercise-with-hint",
      {
        message("Seeing ", data$sectionId, " for the first time.")
      }
    )
  }
)


} # }
```
