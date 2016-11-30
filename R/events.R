

record_event <- function(session, label, event, data) {
  recorder <- getOption("tutor.event_recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial = read_request(session, "tutor.tutorial_id"), 
             user = read_request(session, "tutor.user_id"), 
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



debug_event_recorder <- function(tutorial, user, label, event, data) {
  cat(tutorial, "(", user, ")\n", sep = "")
  cat(event, ": ", label, "\n", sep = "")
  cat(names(data), "\n")
}


