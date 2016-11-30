
initialize_identifiers <- function(session, request) {
  
  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
    else
      NULL
  }
  
  # read tutorial_id from http header (or default to tutorial directory)
  id_header <- as_rook_header(getOption("tutor.http_header_tutorial_id"))
  if (!is.null(id_header) && exists(id_header, envir = request))
    id <- get(id_header, envir = request)
  else
    id <- getwd()
  
  # read user_id from http header (or default to current username)
  user_id_header <- as_rook_header(getOption("tutor.http_header_user_id"))
  if (!is.null(user_id_header) && exists(user_id_header, envir = request))
    user_id <- get(user_id_header, envir = request)
  else 
    user_id <- unname(Sys.info()["user"])
  
  # set their values into session context which can be re-read later
  write_request(session, "tutor.tutorial_id", id)
  write_request(session, "tutor.user_id", user_id)
  
  # return them 
  list(
    tutorial_id = id,
    user_id = user_id
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



