

# one-time initialization for Shiny session
initialize_shiny_session <- function(session) {
  
  # initialize session and user identifiers
  initialize_recording_identifiers(session)
  
  # register http handlers
  register_http_handlers(session)   
}


read_request <- function(session, name, default = NULL) {
  if (!is.null(name)) {
    if (exists(name, envir = session$request))
      get(name, envir = session$request)
    else
      default
  } else {
    default
  }
}

write_request <- function(session, name, value) {
  do.call("unlockBinding", list("request", session))
  session$request[[name]] <- value
  do.call("lockBinding", list("request", session))
}

