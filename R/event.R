event_handlers <- new.env(parent = emptyenv())

#' Register an event handler callback
#'
#' Register an event handler on a per-tutorial basis. Handlers for an event will
#' be fired in the order that they were registered. If
#' `event_register_handler_once()` is used, the callback will execute only one
#' time.
#'
#' @param event The name of an event.
#' @param callback A function to be invoked when an event with a specified name
#'   occurs. The callback must take parameters `session`, `event`, and `data`.
#'
#' @return A function which, if invoked, will remove the callback.
#'
#' @export
event_register_handler <- function(event, callback) {
  if (!is.function(callback) ||
      !identical(names(formals(callback)), c("session", "event", "data")))
  {
    stop("`callback` must be a function that takes three arguments, `session`, `event`, and `data`.")
  }

  if (is.null(event_handlers[[event]])) {
    event_handlers[[event]] <- list()
    attr(event_handlers[[event]], "last_id") <- 0
  }

  id <- attr(event_handlers[[event]], "last_id", TRUE) + 1
  attr(event_handlers[[event]], "last_id") <- id

  # IDs have names like "0000000001", "0000000002", "0000000003", etc.
  id_str <- sprintf("%010d", id)
  event_handlers[[event]][[id_str]] <- callback

  # Use this instead of a local anonymous function, so that we don't capture
  # `callback`, and other objects in the removal function, which might keep some
  # objects from getting GC'd.
  invisible(create_event_handler_remover(event, id_str))
}

#' @name event_register_handler
#' @export
event_register_handler_once <- function(event, callback) {
  cancel_callback <- event_register_handler(
    event,
    function(session, event, data) {
      # Use on.exit() to ensure cancellation in case callback throws an error.
      on.exit(cancel_callback())
      callback(session, event, data)
    }
  )

  invisible(cancel_callback)
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
  record_event(session, event, data)

  if (is.null(event_handlers[[event]])) {
    return(invisible())
  }

  # Handlers for this named event
  handlers <- event_handlers[[event]]

  # Invoke all the callbacks for this event.
  for (handler in handlers) {
    tryCatch(
      handler(session, event, data),
      error = function(e) {
        warning(conditionMessage(e), .call = FALSE)
      }
    )
  }
}
