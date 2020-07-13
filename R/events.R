event_handlers <- new.env(parent = emptyenv())

# Register an event handler on a per-tutorial basis.
register_event_handler <- function(event, callback) {
  if (is.null(event_handlers[[event]])) {
    event_handlers[[event]] <- list()
    last_id <- sprintf("%010d", 0)
  } else {
    last_id <- names(event_handlers[[event]])[[length(event_handlers[[event]])]]
  }

  # IDs have name like "0000000001", "0000000002", "0000000003", etc.
  id <- sprintf("%010d", as.numeric(last_id) + 1)
  event_handlers[[event]][[id]] <- callback

  # Use this instead of a local anonymous function, so that we don't capture
  # `callback`, and other objects in the removal function, which might keep some
  # objects from getting GC'd.
  create_event_handler_remover(event, id)
}

# Returns a function which removes an event handler.
create_event_handler_remover <- function(event, id) {
  function() {
    remove_event_handler(event, id)
  }
}

# Remove an event handler.
remove_event_handler <- function(event, id) {
  if (is.null(event_handlers[[event]]) ||
      is.null(event_handlers[[event]][[id]]))
  {
    return(invisible(FALSE))
  }

  event_handlers[[event]][[id]] <- NULL
  invisible(TRUE)
}


trigger_event <- function(session, event, data) {
  if (is.null(event_handlers[[event]])) {
    return(invisible())
  }

  # Handlers for this named event
  handlers <- event_handlers[[event]]

  # Invoke all the callbacks for this event.

  # NOTE: These are not wrapped in try-catch, so an error will stop all the rest
  # of the callbacks from executing.
  for (handler in handlers) {
    handler(session, data)
  }
}
