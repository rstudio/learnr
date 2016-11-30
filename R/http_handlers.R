


register_http_handlers <- function(session) {
  
  # initialize handler
  session$registerDataObj("initialize", NULL,  function(data, req) {
    
    # initialize identifiers based on http headers (or default
    # identifers used for local mode)
    identifiers <- initialize_identifiers(session, req)
    
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
      body = rpc_json_result(data)
    )
  })
  
  # restore state handler
  session$registerDataObj("restore_state", NULL, rpc_handler(function(input) {
    list(
      submissions = get_all_submissions(session, exercise_output = FALSE)
    )
  }))
  
  # event recording
  session$registerDataObj("record_event", NULL, rpc_handler(function(input) {
    record_event(session = session,
                 label = input$label,
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
    
    # store for later replay
    save_question_submission(session = session, 
                             label = label, 
                             question = question, 
                             answers = answers)
  }))
  
  # help handler
  session$registerDataObj("help",  NULL, rpc_handler(function(input) {
    
  }))
  
  # completion handler
  session$registerDataObj("completion",  NULL, rpc_handler(function(input) {
    
  }))
  
  # diagnostics handler
  session$registerDataObj("diagnotics",  NULL, rpc_handler(function(input) {
    
  }))
  
}


# return a rook wrapper for a function that takes a list and returns a list
# (list contents are automatically converted to/from JSON for rook as required)
rpc_handler <- function(handler) {
  
  function(data, req) {
    
    # get the post data and deserialize it
    input_stream <- req[["rook.input"]]
    input <- jsonlite::fromJSON(input_stream$read_lines())
    
    # call the handler
    result <- handler(input)
    
    # return the result as JSON
    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'application/json'
      ),
      body = rpc_json_result(result)
    )
  }
}

# helper for returning JSON
rpc_json_result <- function(x) {
  jsonlite::toJSON(x, null = "null", force = TRUE)
}



