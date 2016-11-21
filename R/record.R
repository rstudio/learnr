

record <- function(session, label, action, data) {
  recorder <- getOption("tutor.recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial = read_request(session, "tutor.tutorial_id"), 
             user = read_request(session, "tutor.user_id"), 
             label = label,
             action = action, 
             data = data)
  }
  invisible(NULL)
}

record_exercise_error <- function(session, label, code, message) {
  record(session = session,
         label = label,
         action = "exercise_error",
         data = list(
           code = code,
           message = message))
}

record_exercise_submission <- function(session,
                                       label, 
                                       code, 
                                       output, 
                                       checked = FALSE, 
                                       correct = NA) {
  record(session = session,
         label = label,
         action = "exercise_submission",
         data = list(code = code,
                     output = output,
                     checked = checked,
                     correct = correct))
}



debug_recorder <- function(tutorial, user, label, action, data) {
  cat(tutorial, user, "\n", sep = ",")
  cat("[", action, " : ", label, "]\n", sep = "")
  cat(str(data), "\n")
}


initialize_recording_identifiers <- function(session) {
 
  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(name))
    else
      NULL
  }
  
  # read tutorial id and user id from custom headers (if provided)
  id_header <- as_rook_header(getOption("tutor.http_header_tutorial_id"))
  id <- read_request(session, id_header, getwd())
  user_id_header <- as_rook_header(getOption("tutor.http_header_user_id"))
  user_id <- read_request(session, user_id_header, unname(Sys.info()["user"]))
  
  # set their values into session header which can be re-read later
  write_request(session, "tutor.tutorial_id", id)
  write_request(session, "tutor.user_id", user_id)
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


