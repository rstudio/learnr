

register_http_handlers <- function(session) {
  
  response <- list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = jsonlite::toJSON(list(foo = "bar"))
  )
  
  # recorder handler
  session$registerDataObj("record", NULL, function(data, req) {
    
    # get the post data and deserialize it
    input <- req[["rook.input"]]
    params <- jsonlite::fromJSON(input$read_lines())
    
    # record 
    record(label = params$label,
           action = params$action,
           data = params$data)
    
    # return success
    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'text/plain'
      ),
      body = ''
    )
  })
  
  # help handler
  session$registerDataObj("help",  NULL,  function(data, req) {
    response
  })
  
  # completion handler
  session$registerDataObj("completion",  NULL,  function(data, req) {
    response
  })
  
  # diagnostics handler
  session$registerDataObj("diagnotics",  NULL,  function(data, req) {
    response
  })
  
}
