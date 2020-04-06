
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

test_that("initiate_remote_session works", {
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
  cb <- function(sid){
    sess_ids <<- c(sess_ids, sid)
  }
  err_cb <- function(res){
    print(res)
    testthat::fail("Unexpected error from initiate_remote_session")
    failed <<- TRUE
  }

  # Initiate a handful of sessions all at once
  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)
  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)
  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!failed && length(sess_ids) < 3){
    later::run_now()
  }

  expect_equal(failed, FALSE)
  expect_equal(sess_ids, rep("abcd1234", 3))
})

test_that("initiate_remote_session fails with bad status", {
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
  cb <- function(sid){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})

test_that("initiate_remote_session fails with invalid JSON", {
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
  cb <- function(sid){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})

test_that("initiate_remote_session fails with failed curl", {
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
  cb <- function(sid){
    testthat::fail("Expected failure but got success")
    done <<- TRUE
  }
  err_cb <- function(res){
    done <<- TRUE
  }

  initiate_remote_session(pool, paste0(srv$url, "/learnr/"), cb, err_cb)

  while(!done){
    later::run_now()
  }

  # testthat deems this test empty if we don't have any expectations.
  expect_equal(1, 1)
})





