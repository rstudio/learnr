


register_http_handlers <- function(session) {
  
  # initialize handler
  session$registerDataObj("initialize", NULL,  function(data, req) {
    
    # initialize recording identifiers based on http headers (or default
    # identifers used for local mode)
    identifiers <- initialize_recording_identifiers(session, req)
    
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
      body = jsonlite::toJSON(data)
    )
  })
  
  # recorder handler
  session$registerDataObj("record", NULL, rpc_handler(function(input) {
    record(session = session,
           label = input$label,
           action = input$action,
           data = input$data)
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

# return a rook wrapper for a funciton that takes a list and returns a list
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
      body = jsonlite::toJSON(result)
    )
  }
}


