

record_event <- function(session, event, data) {
  recorder <- getOption("tutorial.event_recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial_id = read_request(session, "tutorial.tutorial_id"),
             tutorial_version = read_request(session, "tutorial.tutorial_version"),
             user_id = read_request(session, "tutorial.user_id"),
             event = event,
             data = data)
  }
  invisible(NULL)
}


broadcast_progress_event_to_client <- function(session, event, data) {
  session$sendCustomMessage("tutorial.progress_event", list(
    event = event,
    data = data
  ))
}

broadcast_question_event_to_client <- function(session, label, answer) {
  broadcast_progress_event_to_client(session = session,
                                     event = "question_submission",
                                     data = list(label = label, answer = answer))
}
question_submission_event <- function(session,
                                      label,
                                      question,
                                      answer,
                                      correct) {
  # notify server-side listeners
  record_event(session = session,
               event = "question_submission",
               data = list(label = label,
                           question = question,
                           answer = answer,
                           correct = correct))

  # notify client side listeners
  broadcast_question_event_to_client(session = session,
                                     label = label,
                                     answer = answer)

  # store submission for later replay
  save_question_submission(session = session,
                           label = label,
                           question = question,
                           answer = answer)
}

reset_question_submission_event <- function(session, label, question) {
  # notify server-side listeners
  record_event(session = session,
               event = "question_submission",
               data = list(label = label,
                           question = question,
                           reset = TRUE))

  # notify client side listeners
  broadcast_progress_event_to_client(
    session,
    "question_submission",
    list(label = label, answer = NULL)
  )


  # store submission for later replay
  save_reset_question_submission(session = session,
                           label = label,
                           question = question)
}


section_skipped_event <- function(session, sectionId) {

  # event data
  event_data <- list(sectionId = sectionId)

  # notify server-side listeners
  record_event(session = session,
               event = "section_skipped",
               data = event_data)

  # notify client side listeners
  broadcast_progress_event_to_client(session = session,
                                     event = "section_skipped",
                                     data = event_data)

  # save for later replay
  save_section_skipped(session = session, sectionId = sectionId)
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
               event = "exercise_submission",
               data = list(label = label,
                           code = code,
                           output = output,
                           error_message = error_message,
                           checked = checked,
                           feedback = feedback))

  # notify client side listeners
  if (checked)
    correct <- feedback$correct
  else
    correct <- TRUE
  broadcast_progress_event_to_client(session = session,
                                     event = "exercise_submission",
                                     data = list(label = label, correct = correct))

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

video_progress_event <- function(session, video_url, time, total_time) {

  # data for event
  data <- list(
    video_url = video_url,
    time = time,
    total_time = total_time
  )

  # notify server side listeners
  record_event(session = session,
               event = "video_progress",
               data = data)

  # notify client side listeners
  broadcast_progress_event_to_client(session, "video_progress", data)

  # save for later replay
  save_video_progress(session, video_url, time, total_time)
}

session_start_event <- function(session) {
  record_event(session = session,
               event = "session_start",
               data = list())
}

session_stop_event <- function(session) {
  record_event(session = session,
               event = "session_stop",
               data = list())
}

debug_event_recorder <- function(tutorial_id,
                                 tutorial_version,
                                 user_id,
                                 event,
                                 data) {
  cat(tutorial_id, " (", tutorial_version, "): ", user_id , "\n", sep = "")
  cat("event: ", event, "\n", sep = "")
  utils::str(data)
  cat("\n")
}


