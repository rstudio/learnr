

record_event <- function(session, label, event, data) {
  recorder <- getOption("tutor.event_recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial_id = read_request(session, "tutor.tutorial_id"), 
             tutorial_version = read_request(session, "tutor.tutorial_version"),
             user_id = read_request(session, "tutor.user_id"), 
             label = label,
             event = event, 
             data = data)
  }
  invisible(NULL)
}

exercise_error_event <- function(session, label, code, message) {
  record_event(session = session,
               label = label,
               event = "exercise_error",
               data = list(
                code = code,
                message = message))
}

question_submission_event <- function(session,
                                      label,
                                      question,
                                      answers,
                                      correct) {
  record_event(session = session,
               label = label,
               event = "question_submission",
               data = list(question = question,
                           answers = answers,
                           correct = correct))
}

exercise_submission_event <- function(session,
                                      label, 
                                      code, 
                                      output, 
                                      checked = FALSE, 
                                      correct = NULL) {
  record_event(session = session,
               label = label,
               event = "exercise_submission",
               data = list(code = code,
                           output = output,
                           checked = checked,
                           correct = correct))
}



debug_event_recorder <- function(tutorial_id, 
                                 tutorial_version,
                                 user_id, 
                                 label, 
                                 event, 
                                 data) {
  cat(tutorial_id, " (", tutorial_version, "): ", user_id , "\n", sep = "")
  cat(label, ": ", event, "\n", sep = "")
}


