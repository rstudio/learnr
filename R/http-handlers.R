


register_http_handlers <- function(session, metadata) {
  
  # initialize handler
  session$registerDataObj("initialize", NULL,  function(data, req) {
    
    # parameters
    location <- json_rpc_input(req)$location
    
    # initialize session state
    identifiers <- initialize_session_state(session, metadata, location, req)
    
    # data payload to return
    data <- list(
      identifiers = identifiers
    )
    
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
  session$registerDataObj("restore_state", NULL, rpc_handler(function(input) {
    
    # forward any client stored objects into our own storage
    if (!is.null(input))
      initialize_objects_from_client(session, input)
    
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
    
    # return data
    list(
      client_state = client_state,
      submissions = submissions,
      video_progress = video_progress,
      progress_events = progress_events
    )
  }))
  
  # remove state handler
  session$registerDataObj("remove_state", NULL, rpc_handler(function(input) {
    remove_all_objects(session)
  }))
  
  # event recording
  session$registerDataObj("record_event", NULL, rpc_handler(function(input) {
    record_event(session = session,
                 event = input$event,
                 data = input$data)
  }))
  
  # question submission handler
  session$registerDataObj("question_submission", NULL, rpc_handler(function(input) {
    
    # extract inputs
    label <- input$label
    question <- input$question
    answers <- input$answers
    correct <- input$correct
    
    # fire event
    question_submission_event(session = session,
                              label = label,
                              question = question,
                              answers = answers,
                              correct = correct)
  }))
  
  # video progress handler
  session$registerDataObj("video_progress", NULL, rpc_handler(function(input) {
    
    # extract inputs
    video_url <- input$video_url
    time <- input$time
    total_time <- input$total_time
    
    # fire event
    video_progress_event(session = session,
                         video_url = video_url,
                         time = time,
                         total_time = total_time)
  }))
  
  # client state handler
  session$registerDataObj("set_client_state",  NULL, rpc_handler(function(input) {
    save_client_state(session, input)
  }))
  
  # help handler
  session$registerDataObj("help",  NULL, rpc_handler(function(input) {
    
  }))
  
  # completion handler
  session$registerDataObj("completion",  NULL, rpc_handler(function(input) {
    
    # read params
    line <- input
    Encoding(line) <- "UTF-8"
    
    # set completion settings
    original <- rc.options()
    rc.options(package.suffix = "::",
               funarg.suffix = " = ",
               function.suffix = "(")
    on.exit(
      rc.options(package.suffix = original$package.suffix,
                 funarg.suffix = original$funarg.suffix,
                 function.suffix = original$function.suffix),
      add = TRUE
    )
    
    # update rcompgen state
    completions <- character()
    try(silent = TRUE, {
      utils:::.assignLinebuffer(line)
      utils:::.assignEnd(nchar(line))
      token <- utils:::.guessTokenFromLine()
      utils:::.completeToken()
      completions <- as.character(utils:::.retrieveCompletions())
    })
    
    # remove a leading '::', ':::' from autocompletion results, as
    # those won't be inserted as expected in Ace
    completions <- gsub("[^:]+:{2,3}(.)", "\\1", completions)
    completions <- completions[nzchar(completions)]
    
    # return completions
    as.list(completions)
  }))
  
  # diagnostics handler
  session$registerDataObj("diagnotics",  NULL, rpc_handler(function(input) {
    
  }))
  
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



