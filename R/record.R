

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
  cat(tutorial, "(", user, ")\n", sep = "")
  cat(action, ": ", label, "\n", sep = "")
  cat(str(data), "\n")
}


initialize_recording_identifiers <- function(session, request) {
 
  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
    else
      NULL
  }
  
  # read tutorial id and user id from custom headers (if provided)
  id_header <- as_rook_header(getOption("tutor.http_header_tutorial_id"))
  if (!is.null(id_header) && exists(id_header, envir = request))
    id <- get(id_header, envir = request)
  else
    id <- getwd()
  user_id_header <- as_rook_header(getOption("tutor.http_header_user_id"))
  if (!is.null(user_id_header) && exists(user_id_header, envir = request))
    user_id <- get(user_id_header, envir = request)
  else 
    user_id <- unname(Sys.info()["user"])
  
  # set their values into session header which can be re-read later
  write_request(session, "tutor.tutorial_id", id)
  write_request(session, "tutor.user_id", user_id)
}


