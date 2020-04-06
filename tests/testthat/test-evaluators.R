
context("evaluators")

# TODO: consider using testthat::setup/teardown, but we want to conditionally
#  skip these tests which makes that more complicated.
# @param responses - a list indexed by `<verb> <path>` which maps to an httpuv
#   response. e.g. list(`GET /` = list(status = 200L, headers = list(), body = "OK"))
start_server <- function(responses){
  srv <- NULL
  result <- new.env(parent=emptyenv())
  result$reqs <- NULL

  result$port <- httpuv::randomPort()
  result$url <- paste0("http://localhost:", result$port)
  cat("Starting server on port", result$port, "\n")

  req_to_id <- function(req){
    paste(req$REQUEST_METHOD, req$PATH_INFO)
  }

  # An HTTP server that stashes away all of the requests for later analysis
  srv <- httpuv::startServer("127.0.0.1", port = result$port, list(
    call = function(req) {

      body <- req$rook.input$read()
      result$reqs[[ length(result$reqs) + 1 ]] <<- list(req = req, body=body)

      # See if this method + path has a defined response
      id <- req_to_id(req)
      if (!is.null(responses[[id]])){
        return(responses[[id]])
      }

      # Otherwise, 404
      list(
        status = 404L,
        headers = list(
          'Content-Type' = 'text/html'
        ),
        body = paste("Not found:", id)
      )
    }
  ))
  result$stop <- srv$stop

  result
}

test_that("initiate_remote_session works one-at-a-time", {
  testthat::skip_on_cran()

  responses <- list(`POST /learnr/` = list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = '{"id": "abcd1234"}'
  ))

  srv <- start_server(responses)
  on.exit(srv$stop(), add = TRUE)

  sess_id <- initiate_remote_session(paste0(srv$url, "/learnr/"))

  expect_equal(sess_id, "abcd1234")
})








