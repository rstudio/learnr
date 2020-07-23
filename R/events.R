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


#' Wrap an expression that will be executed one time in an event handler
#'
#' This wraps an expression so that it will be executed one time for a tutorial,
#' based on some condition. The first time the condition is true, the expression
#' will be executed; after that, the expression will not be evaluated again.
#'
#' The execution state is stored so that if the expression is executed, then the
#' user quits the tutorial and then returns to it, the expression will not be
#' executed a second time.
#'
#' A common use for `one_time` is to execute an expression when a section is
#' viewed for the first time.
#'
#' @param session A Shiny session object.
#' @param cond A condition that is used as a filter. The first time the
#'   condition evaluates to true, `expr` will be evaluated; after that, `expr`
#'   will not be evaluated again.
#' @param expr An expression that will be evaluated once, the first time that
#'   `cond` is true.
#' @param label A unique identifier. This is used as an ID for the condition and
#'   expression; if two calls to `one_time()` uses the same label, there will be
#'   an ID collision and only one of them will execute. By default, `cond` is
#'   deparsed and used as the label.
#'
#' @examples
#' \dontrun{
#' # This goes in a {r context="server-start"} chunk
#'
#' # The expression with message() will be executed the first time the user
#' # sees the section with ID "section-exercise-with-hint".
#' event_register_handler("section_viewed",
#'   function(session, event, data) {
#'     one_time(
#'       session,
#'       data$sectionId == "section-exercise-with-hint",
#'       {
#'         message("Seeing ", data$sectionId, " for the first time.")
#'       }
#'     )
#'   }
#' )
#'
#'
#' }
#' @export
one_time <- function(session, cond, expr, label = deparse(substitute(cond))) {
  # This is meant to be called within an event handler, instead of being
  # implemented as an event handler that removes itself. The reason that the
  # latter method isn't used is because it's possible that two simultaneous user
  # sessions will use be running, and these event handlers are installed at an
  # app-level (not session-level) scope.

    if (!isTRUE(cond)) {
    return()
  }

  object_id <- ns_wrap("one_time_", digest::digest(label, "xxhash64"))

  if (length(get_object(session = session, object_id = object_id)) == 0) {
    first_time <- TRUE
    save_object(
      session = session,
      object_id = object_id,
      data = tutorial_object(
        type = "one_time",
        data = list(cond = label)
      )
    )
  } else {
    first_time <- FALSE
  }

  if (first_time) {
    expr
  }
}
