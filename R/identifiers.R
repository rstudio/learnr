
initialize_identifiers <- function(session, request) {
  
  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
    else
      NULL
  }
  
  # function to initialize an identifier (read from http header or take default)
  initialize_identifer <- function(identifier, default) {
    
    # determine whether a custom header provides the value (fallback to default)
    header <- as_rook_header(getOption(sprintf("tutor.http_header_%s", identifier)))
    if (!is.null(header) && exists(header, envir = request))
      value <- get(header, envir = request)
    else
      value <- default
    
    # write it into the request for reading later on
    write_request(session, sprintf("tutor.%s", identifier), value)
    
    # return the value
    value
  }
  
  # initialize and return identifiers
  list(
    tutorial_id = initialize_identifer("tutorial_id", default = getwd()),
    tutorial_version = initialize_identifer("tutorial_version", default = "1.0"),
    user_id = initialize_identifer("user_id", default = unname(Sys.info()["user"]))
  )
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



