

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


broadcast_progress_event_to_client <- function(session, event, label, correct) {
  session$sendCustomMessage("tutor.progress_event", list(
    event = event,
    label = label,
    correct = correct
  ))
}


question_submission_event <- function(session,
                                      label,
                                      question,
                                      answers,
                                      correct) {
  # notify server-side listeners
  record_event(session = session,
               label = label,
               event = "question_submission",
               data = list(question = question,
                           answers = answers,
                           correct = correct))
  
  # notify client side listeners
  broadcast_progress_event_to_client(session = session, 
                                     event = "question_submission", 
                                     label = label, 
                                     correct = correct)
  
  # store submission for later replay
  save_question_submission(session = session, 
                           label = label, 
                           question = question, 
                           answers = answers,
                           correct = correct)
}

exercise_submission_event <- function(session,
                                      label, 
                                      code, 
                                      output, 
                                      error_message,
                                      checked = FALSE, 
                                      feedback = NULL) {
  # notify server-side listeners
  record_event(session = session,
               label = label,
               event = "exercise_submission",
               data = list(code = code,
                           output = output,
                           error_message = error_message,
                           checked = checked,
                           feedback = feedback))
  
  # notify client side listeners
  if (checked)
    correct <- feedback$correct
  else
    correct <- NULL
  broadcast_progress_event_to_client(session = session, 
                                     event = "exercise_submission", 
                                     label = label, 
                                     correct = correct)
  
  # save submission for later replay
  save_exercise_submission(
    session = session,
    label = label,
    code = code,
    output = output,
    error_message = error_message,
    checked = checked,
    feedback = feedback
  )
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


