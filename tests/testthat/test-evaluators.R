
context("evaluators")

pool <- curl::new_pool(total_con = 5, host_con = 5)

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

test_that("initiate_external_session works", {
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

  failed <- FALSE
  sess_ids <- NULL
  cb <- function(sid, cookiefile){
    sess_ids <<- c(sess_ids, sid)
  }
  err_cb <- function(res){
    print(res)
    testthat::fail("Unexpected error from initiate_external_session")
    failed <<- TRUE
  }

  # Initiate a handful of sessions all at once
  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)
  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)
  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!failed && length(sess_ids) < 3){
    later::run_now()
  }

  expect_equal(failed, FALSE)
  expect_equal(sess_ids, rep("abcd1234", 3))

  expect_equal(srv$reqs[[1]]$req$CONTENT_LENGTH, "0")
})

test_that("initiate_external_session fails with bad status", {
  testthat::skip_on_cran()

  responses <- list(`POST /learnr/` = list(
    status = 500L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = '{"id": "abcd1234"}'
  ))

  srv <- start_server(responses)
  on.exit(srv$stop(), add = TRUE)

  done <- FALSE
  cb <- function(sid, cookiefile){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})

test_that("initiate_external_session fails with invalid JSON", {
  testthat::skip_on_cran()

  responses <- list(`POST /learnr/` = list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = 'this is not the JSON you seek'
  ))

  srv <- start_server(responses)
  on.exit(srv$stop(), add = TRUE)

  done <- FALSE
  cb <- function(sid, cookiefile){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})

test_that("initiate_external_session fails with failed curl", {
  testthat::skip_on_cran()

  responses <- list(`POST /learnr/` = list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = '{"id": "abcd1234"}'
  ))

  # Start and stop the server as a way to obtain a port number that's likely
  # inavtive.
  srv <- start_server(responses)
  srv$stop()

  done <- FALSE
  cb <- function(sid, cookiefile){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_external_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})


test_that("external_evaluator works", {
  testthat::skip_on_cran()

  tf <- tempfile()
  on.exit({unlink(tf)})
  mock_initiate <- function(pool, url, callback, err_callback){
    callback("abcd1234", tf)
  }

  mockResult <- list(html_output = "hi")
  mockResponse <- list(
    status = 200L,
    headers = list(
      'Content-Type' = 'application/json'
    ),
    body = jsonlite::toJSON(mockResult)
  )

  responses <- list(
    `POST /learnr/abcd1234` = mockResponse,
    `POST /learnr/efgh5678` = mockResponse
  )

  srv <- start_server(responses)
  on.exit(srv$stop(), add = TRUE)

  re <- internal_external_evaluator(srv$url, 5, mock_initiate)

  mockSession <- list(onSessionEnded = function(callback){})

  # Start a couple of sessions concurrently
  e <- re(NULL, 30, list(options = list(exercise.timelimit = 5)), mockSession)
  # Simulate a session that already has an evaluator ID stashed
  e2 <- re(NULL, 30, list(options = list(exercise.timelimit = 5)),
           list(userData = c(mockSession, `.external_evaluator_session_id` = "efgh5678")))
  e$start()
  e2$start()

  while(!e$completed() || !e2$completed()) {
    later::run_now()
  }

  res <- e$result()

  # Check that it applied the HTML class to the html_output property.
  expect_s3_class(res$html_output, "html")

  expect_equal(e$result(), e2$result())

  # Requests may be stored in either order
  if (srv$reqs[[1]]$req$PATH_INFO == "/learnr/abcd1234") {
    expect_equal(srv$reqs[[2]]$req$PATH_INFO, "/learnr/efgh5678")
  } else if (srv$reqs[[1]]$req$PATH_INFO == "/learnr/efgh5678") {
    expect_equal(srv$reqs[[2]]$req$PATH_INFO, "/learnr/abcd1234")
  } else {
    print(srv$reqs[[1]]$req$PATH_INFO)
    testthat::fail("Unrecognized request path")
  }
})

test_that("external_evaluator handles initiate failures", {
  mock_initiate <- function(pool, url, callback, err_callback){
    err_callback(list())
  }

  re <- internal_external_evaluator("http://doesntmatter", 5, mock_initiate)

  e <- re(NULL, 30, list(options = list(exercise.timelimit = 5)), list())
  e$start()

  print(e$result())
  expect_equal(e$result()$error_message, "Error initiating session for external requests. Please try again later")
})

test_that("", {
  testthat::skip_on_cran()

  mockResult <- list(html_output = "hi")

  responses <- list(
    `POST /learnr/badstatus` = list(
      status = 500L,
      headers = list(
        'Content-Type' = 'application/json'
      ),
      body = jsonlite::toJSON(mockResult)
    ),
    `POST /learnr/invalidjson` = list(
      status = 200L,
      headers = list(
        'Content-Type' = 'application/json'
      ),
      body = "I am not JSON!"
    )
  )

  srv <- start_server(responses)
  on.exit(srv$stop(), add = TRUE)

  ### Test with a bad status
  tf <- tempfile()
  on.exit({unlink(tf)})
  re <- internal_external_evaluator(srv$url, 5,
    function(pool, url, callback, err_callback){ callback("badstatus", tf) })

  # Start a session
  mockSession <- list(onSessionEnded = function(callback){})
  e <- re(NULL, 30, list(options = list(exercise.timelimit = 5)), mockSession)
  e$start()

  while(!e$completed()) {
    later::run_now()
  }

  res <- e$result()
  expect_match(res$error_message, "^Error submitting external exercise")

  ### Test with invalid JSON
  tf <- tempfile()
  on.exit({unlink(tf)})
  re <- internal_external_evaluator(srv$url, 5,
    function(pool, url, callback, err_callback){ callback("invalidjson", tf) })

  # Start a session
  e <- re(NULL, 30, list(options = list(exercise.timelimit = 5)), mockSession)
  e$start()

  while(!e$completed()) {
    later::run_now()
  }

  res <- e$result()
  expect_match(res$error_message, "^Error submitting external exercise")
})
