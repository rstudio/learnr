# Register an event handler callback

Register an event handler on a per-tutorial basis. Handlers for an event
will be fired in the order that they were registered.

## Usage

``` r
event_register_handler(event, callback)
```

## Arguments

- event:

  The name of an event.

- callback:

  A function to be invoked when an event with a specified name occurs.
  The callback must take parameters `session`, `event`, and `data`.

## Value

A function which, if invoked, will remove the callback.

## Details

In most cases, this will be called within a learnr document. If that is
the case, then the handler will exist as long as the document (that is,
the Shiny application) is running.

If this function is called in a learnr .Rmd document, it should be in a
chunk with `context="server-start"`. If it is called with
`context="server"`, the handler will be registered at least two times
(once for the application as a whole, and once per user session).

If this function is called outside of a learnr document, then the
handler will persist until the learnr package is unloaded, typically
when the R session is stopped.
