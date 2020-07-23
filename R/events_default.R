
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
    "session_start",
    function(session, event, data) {
      # The observer here needs to be registered at session_start; if it is
      # called in initialize_tutorial(), then the "section_viewed" event fire
      # too soon, which will cause errors when it calls get_object(), because
      # the storage system won't yet be ready.
      #
      # This observer watches input$`tutorial-visible-sections`, and wraps it
      # so that it fires a "section_viewed" event when a new section is added
      # to that input value.
      last_visible_sections <- character(0)
      observe({
        visible_sections <- session$input$`tutorial-visible-sections`

        new_visible <- setdiff(visible_sections, last_visible_sections)
        for (section in new_visible) {
          event_trigger(
            session,
            "section_viewed",
            data = list(sectionId = section)
          )
        }

        # Note: `visible_sections` could have more or fewer items from
        # `last_visible_sections`; the setdiff() above only detects if it has
        # more. Always save the `visible_sections`.
        last_visible_sections <<- visible_sections
      })
    }
  )

  event_register_handler(
    "section_viewed",
    function(session, event, data) {
      label <- ns_wrap("section_viewed_", data$sectionId)

      if (length(get_object(session = session, object_id = label)) == 0) {
        first_time <- TRUE
        save_object(
          session = session,
          object_id = label,
          data = tutorial_object(
            type = "section_viewed",
            data = list(sectionId = data$sectionId)
          )
        )
      } else {
        first_time <- FALSE
      }

      if (first_time) {
        event_trigger(
          session,
          "section_viewed_first_time",
          data = list(sectionId = data$sectionId)
        )
      }
    }
  )

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
