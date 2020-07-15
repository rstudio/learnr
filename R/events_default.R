
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


register_default_event_handlers <- function() {
  event_register_handler(
    "question_submission",
    function(session, event, data) {
      # notify client side listeners
      broadcast_question_event_to_client(
        session = session,
        label   = data$label,
        answer  = data$answer
      )

      # store submission for later replay
      save_question_submission(
        session  = session,
        label    = data$label,
        question = data$question,
        answer   = data$answer
      )
    }
  )

  event_register_handler(
    "reset_question_submission",
    function(session, event, data) {
      # notify client side listeners
      broadcast_progress_event_to_client(
        session,
        "question_submission",
        list(label = data$label, answer = NULL)
      )


      # store submission for later replay
      save_reset_question_submission(
        session  = session,
        label    = data$label,
        question = data$question
      )
    }
  )

  event_register_handler(
    "section_skipped",
    function(session, event, data) {
      # notify client side listeners
      broadcast_progress_event_to_client(
        session = session,
        event = "section_skipped",
        data = data
      )

      # save for later replay
      save_section_skipped(session = session, sectionId = data$sectionId)
    }
  )


  event_register_handler(
    "exercise_result",
    function(session, event, data) {
      # notify client side listeners
      if (data$checked)
        correct <- data$feedback$correct
      else
        correct <- TRUE
      broadcast_progress_event_to_client(
        session = session,
        event = "exercise_submission",
        data = list(label = data$label, correct = correct)
      )

      # save submission for later replay
      save_exercise_submission(
        session       = session,
        label         = data$label,
        code          = data$code,
        output        = data$output,
        error_message = data$error_message,
        checked       = data$checked,
        feedback      = data$feedback
      )
    }
  )


  event_register_handler(
    "video_progress",
    function(session, event, data) {
      # notify client side listeners
      broadcast_progress_event_to_client(session, "video_progress", data)

      # save for later replay
      save_video_progress(session, data$video_url, data$time, data$total_time)
    }
  )
}
