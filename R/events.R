event_handlers <- new.env(parent = emptyenv())

#' Register an event handler callback
#'
#' Register an event handler on a per-tutorial basis. Handlers for an event will
#' be fired in the order that they were registered.
#'
#' In most cases, this will be called within a learnr document. If that is the
#' case, then the handler will exist as long as the document (that is, the Shiny
#' application) is running.
#'
#' If this function is called in a learnr .Rmd document, it should be in a chunk
#' with `context="server-start"`. If it is called with `context="server"`, the
#' handler will be registered at least two times (once for the application as a
#' whole, and once per user session).
#'
#' If this function is called outside of a learnr document, then the handler
#' will persist until the learnr package is unloaded, typically when the R
#' session is stopped.
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
  cancel_handler <- create_event_handler_remover(event, id_str)

  # If a handler is registered in a learnr document, then it will last as long
  # as the document (Shiny app) is running -- it will not be scoped to the
  # specific user session. This is because these event handlers take `session`
  # as an argument.
  if (shiny::isRunning()) {
    shiny::onStop(cancel_handler, session = NULL)
  }

  invisible(cancel_handler)
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

# Clear all event handlers
event_handlers_reset <- function() {
  rm(
    list = ls(event_handlers, all.names = TRUE),
    envir = event_handlers
  )
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
