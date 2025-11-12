register_http_handlers <- function(session, metadata) {
  session$userData$learnr_state <- reactiveVal("start")

  # parent environment for completions (see discussion in setup_exercise_handler
  # for why this is chosen as the completion/execution parent)
  server_envir <- parent.env(parent.env(parent.frame()))

  # environment used for hosting state (e.g. for chunks)
  state <- new.env(parent = emptyenv())

  # initialize handler
  session$registerDataObj("initialize", NULL, function(data, req) {
    # parameters
    location <- json_rpc_input(req)$location

    # initialize session state
    identifiers <- initialize_session_state(session, metadata, location, req)

    # data payload to return
    data <- list(
      identifiers = identifiers
    )

    # Now that we've initialized the session state, emit the start event
    event_trigger(session, "session_start")

    session$userData$learnr_state("initialized")
    # return identifers
    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'application/json'
      ),
      body = json_rpc_result(data)
    )
  })

  # restore state handler
  session$registerDataObj(
    "restore_state",
    NULL,
    rpc_handler(function(input) {
      # forward any client stored objects into our own storage
      if (!is.null(input)) {
        initialize_objects_from_client(session, input)
      }

      # get state objects
      state_objects <- get_all_state_objects(session, exercise_output = FALSE)

      # create submissions from state objects
      submissions <- submissions_from_state_objects(state_objects)

      # create video progress from state objects
      video_progress <- video_progress_from_state_objects(state_objects)

      # create progress events from state objects
      progress_events <- progress_events_from_state_objects(state_objects)

      # get client state
      client_state <- get_client_state(session)

      session$userData$learnr_state("restored")

      # return data
      list(
        client_state = client_state,
        submissions = submissions,
        video_progress = video_progress,
        progress_events = progress_events
      )
    })
  )

  # remove state handler
  session$registerDataObj(
    "remove_state",
    NULL,
    rpc_handler(function(input) {
      remove_all_objects(session)
    })
  )

  # event recording
  session$registerDataObj(
    "record_event",
    NULL,
    rpc_handler(function(input) {
      # Augment the data with the label
      input$data$label <- input$label

      record_event(session = session, event = input$event, data = input$data)
    })
  )

  # # question submission handler
  # session$registerDataObj("question_submission", NULL, rpc_handler(function(input) {
  #   cat("--- question_submission handler called\n")
  #
  #   # extract inputs
  #   label <- input$label
  #   question <- input$question
  #   answers <- input$answers
  #   correct <- input$correct
  #
  #   # fire event
  #   question_submission_event(session = session,
  #                             label = label,
  #                             question = question,
  #                             answers = answers,
  #                             correct = correct)
  # }))

  # video progress handler
  session$registerDataObj(
    "video_progress",
    NULL,
    rpc_handler(function(input) {
      # extract inputs
      video_url <- input$video_url
      time <- input$time
      total_time <- input$total_time

      # fire event
      event_trigger(
        session,
        "video_progress",
        data = list(
          video_url = video_url,
          time = time,
          total_time = total_time
        )
      )
    })
  )

  # exercise skipped event
  session$registerDataObj(
    "section_skipped",
    NULL,
    rpc_handler(function(input) {
      # extract inputs
      sectionId <- input$sectionId

      # fire event
      event_trigger(
        session,
        "section_skipped",
        data = list(sectionId = sectionId)
      )
    })
  )

  # client state handler
  session$registerDataObj(
    "set_client_state",
    NULL,
    rpc_handler(function(input) {
      save_client_state(session, input)
    })
  )

  # help handler
  session$registerDataObj("help", NULL, rpc_handler(function(input) {}))

  # setup chunk handler
  session$registerDataObj(
    "initialize_chunk",
    NULL,
    rpc_handler(function(input) {
      params <- input

      # evaluate setup code to prime environment
      label <- as.character(params$label)
      code <- paste(params$setup_code, collapse = "\n")

      # no setup chunk / label? nothing to do
      if (!(nzchar(label) && nzchar(code))) {
        return()
      }

      # evaluate code in environment to prime
      Encoding(code) <- "UTF-8"
      state[[label]] <- new.env()
      eval(parse(text = code, encoding = "UTF-8"), envir = state[[label]])
    })
  )

  # completion handler
  session$registerDataObj(
    "completion",
    NULL,
    rpc_handler(function(input) {
      # read params
      line <- as.character(input$contents)
      label <- as.character(input$label)

      Encoding(line) <- "UTF-8"

      auto_complete_r(line, label, state)
    })
  )

  # diagnostics handler
  session$registerDataObj("diagnotics", NULL, rpc_handler(function(input) {}))

  # this is a "bat signal" to let the JS side know that the Shiny
  # server is ready to handle http requests
  session$sendCustomMessage("tutorial_isServerAvailable", "true")
}


# return a rook wrapper for a function that takes a list and returns a list
# (list contents are automatically converted to/from JSON for rook as required)
rpc_handler <- function(handler) {
  function(data, req) {
    # get the input
    input <- json_rpc_input(req)

    # call the handler
    result <- handler(input)

    # return the result as JSON
    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'application/json'
      ),
      body = json_rpc_result(result)
    )
  }
}

# get the json from a request body
json_rpc_input <- function(req) {
  input_stream <- req[["rook.input"]]
  jsonlite::fromJSON(input_stream$read_lines())
}

# helper for returning JSON
json_rpc_result <- function(x) {
  jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", force = TRUE)
}
