

register_editor_handlers <- function(session) {
  
  response <- list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = jsonlite::toJSON(list(foo = "bar"))
  )
  
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
