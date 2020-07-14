event_handlers <- new.env(parent = emptyenv())

# Register an event handler on a per-tutorial basis. Handlers for an event will
# be fired in the order that they were registered.
event_register_handler <- function(event, callback) {
  if (!is.function(callback) ||
      !all(names(formals(callback)) == c("session", "event", "data")))
  {
    stop("`callback` must be a function that takes three arguments, `session`, `event`, and `data`.")
  }

  if (is.null(event_handlers[[event]])) {
    event_handlers[[event]] <- list()
    last_id <- sprintf("%010d", 0)
  } else {
    last_id <- names(event_handlers[[event]])[[length(event_handlers[[event]])]]
  }

  # IDs have names like "0000000001", "0000000002", "0000000003", etc.
  id <- sprintf("%010d", as.numeric(last_id) + 1)
  event_handlers[[event]][[id]] <- callback

  # Use this instead of a local anonymous function, so that we don't capture
  # `callback`, and other objects in the removal function, which might keep some
  # objects from getting GC'd.
  invisible(create_event_handler_remover(event, id))
}

# Returns a function which removes an event handler.
create_event_handler_remover <- function(event, id) {
  function() {
    event_remove_handler(event, id)
  }
}

# Remove an event handler.
event_remove_handler <- function(event, id) {
  if (is.null(event_handlers[[event]]) ||
      is.null(event_handlers[[event]][[id]]))
  {
    return(invisible(FALSE))
  }

  event_handlers[[event]][[id]] <- NULL
  invisible(TRUE)
}


event_trigger <- function(session, event, data = list()) {
  if (is.null(event_handlers[[event]])) {
    return(invisible())
  }

  # Handlers for this named event
  handlers <- event_handlers[[event]]

  # Invoke all the callbacks for this event.

  # NOTE: These are not wrapped in try-catch, so an error will stop all the rest
  # of the callbacks from executing.
  for (handler in handlers) {
    handler(session, event, data)
  }
}
