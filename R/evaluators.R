
# inline execution evaluator
inline_evaluator <- function(expr, timelimit, ...) {

  result <- NULL

  list(
    start = function() {

      # setTimeLimit -- if the timelimit is exceeeded an error will occur
      # during knit which we will catch and format within evaluate_exercise
      setTimeLimit(elapsed=timelimit, transient=TRUE);
      on.exit(setTimeLimit(cpu=Inf, elapsed=Inf, transient=FALSE), add = TRUE);

      # execute and capture result
      result <<- tryCatch(
        force(expr),
        error = function(e) {
          # TODO: could grepl the error message to determine if the error was due
          # to an exceeded timeout.
          error_result(e$message, timeout_exceeded = NA)
        }
      )
    },

    completed = function() {
      TRUE
    },

    result = function() {
      result
    }
  )
}

# forked execution evaluator
forked_evaluator <- function(expr, timelimit, ...) {

  # closure members
  job <- NULL
  start_time <- NULL
  result <- NULL

  # helper to call a hook function
  call_hook <- function(name, default = NULL) {
    hook <- getOption(paste0("tutorial.exercise.evaluator.", name))
    if (!is.null(hook))
      hook(job$pid)
    else if (!is.null(default))
      default(job$pid)
  }

  # default cleanup function
  default_cleanup <- function(pid) {
    system(paste("kill -9", pid))
  }

  list(

    start = function() {
      start_time <<- Sys.time()
      job <<- parallel::mcparallel(mc.interactive = FALSE, {

        # close all connections
        closeAllConnections()

        # call onstart hook
        call_hook("onstart")

        # evaluate the expression
        force(expr)
      })
    },

    completed = function() {

      # attempt to collect the result
      collect <- parallel::mccollect(jobs = job, wait = FALSE, timeout = 0.01)

      # got result
      if (!is.null(collect)) {

        # final reaping of process
        parallel::mccollect(jobs = job, wait = FALSE)

        # call cleanup hook
        call_hook("oncleanup", default = default_cleanup)

        # return result
        result <<- collect[[1]]

        # check if it's an error and convert it to an html error if it is
        if(inherits(result, "try-error"))
          result <<- error_result(result, timeout_exceeded = FALSE)

        TRUE
      }

      # hit timeout
      else if ((Sys.time() - start_time) >= timelimit) {

        # call cleanup hook
        call_hook("oncleanup", default = default_cleanup)

        # return error result
        result <<- error_result(timeout_error_message(), timeout_exceeded = TRUE)
        TRUE
      }

      # not yet completed
      else {
        FALSE
      }
    },

    result = function() {
      result
    }
  )
}

#' Remote execution evaluator
#'
#' @param endpoint The HTTP(S) endpoint to POST the exercises to
#' @param max_curl_conns The maximum number of simultaneous HTTP requests to the
#'   endpoint.
#' @import curl
#' @export
new_remote_evaluator <- function(
  endpoint = getOption("tutorial.remote.host", Sys.getenv("TUTORIAL_REMOTE_EVALUATOR_HOST", NA)),
  max_curl_conns = 50){

  internal_new_remote_evaluator(endpoint, max_curl_conns)
}

# An internal version of new_remote_evaluator that allows us to stub some calls
# for testing.
internal_new_remote_evaluator <- function(
  endpoint,
  max_curl_conns,
  initiate = initiate_remote_session()){

  if (is.na(endpoint)){
    stop("You must specify an endpoint explicitly as a parameter, or via the `tutorial.remote.host` option, or the `TUTORIAL_REMOTE_EVALUATOR_HOST` environment variable")
  }

  # Trim trailing slash
  endpoint <- sub("/+$", "", endpoint)

  function(expr, timelimit, exercise, session, ...) {

    result <- NULL
    pool <- curl::new_pool(total_con = max_curl_conns, host_con = max_curl_conns)

    list(
      start = function() {

        # The actual workhorse here -- called once we have a session ID on the remote evaluator
        submit_req <- function(sess_id){
          # Create curl request
          json <- jsonlite::toJSON(exercise, auto_unbox = TRUE)

          handle <- curl::new_handle(customrequest = "POST",
                                     postfields = json,
                                     postfieldsize = nchar(json),
                                     timeout_ms = exercise$options$exercise.timelimit * 1000 + 5000)
          curl::handle_setheaders(handle, "Content-Type" = "application/json")

          url <- paste0(endpoint, "/learnr/", sess_id)

          done_cb <- function(res){
            tryCatch({
              if (res$status != 200){
                err_callback(res)
                return()
              }

              r <- rawToChar(res$content)
              p <- jsonlite::fromJSON(r)
              p$html_output <- htmltools::HTML(p$html_output)
              result <<- p
            }, error = function(e){
              print(e)
              fail_cb(res)
            })
          }

          fail_cb <- function(res){
            print("Error submitting remote exercise:")
            print(res)
            result <<- error_result("Error submitting remote exercise. Please try again later")
          }

          curl::curl_fetch_multi(url, handle = handle, done = done_cb, fail = fail_cb)

          poll <- function(){
            res <- curl::multi_run(timeout = 0)
            if (res$pending > 0){
              later::later(poll, delay = 0.1)
            }
          }
          poll()
        }

        # Initiate a session
        if (is.null(session$userData$.remote_evaluator_session_id)){
          rs <- initiate(pool, paste0(endpoint, "/learnr/"), callback = function(sid){
            # Stash the session ID for future use and fire the actual request
            session$userData$.remote_evaluator_session_id <- sid
            submit_req(sid)
          }, err_callback = function(res){
            print(res)
            result <<- error_result("Error initiating session for remote requests. Please try again later")
          })
        } else {
          # We already have an ID, invoke immediately
          submit_req(session$userData$.remote_evaluator_session_id)
        }
      },

      completed = function() {
        !is.null(result)
      },

      result = function() {
        result
      }
    )
  }
}

#' Obtains a unique session ID
#' @param pool the curl pool to use for this request
#' @param url The URL to POST to to get a session
#' @param callback The callback to invoke on success. Provides one parameter:
#'   the session ID
#' @param err_callback The callback to invoke on error. Provides one parameter:
#'   the err'ing response
#' @noRd
initiate_remote_session <- function(pool, url, callback, err_callback){
  handle <- curl::new_handle(post=1)

  done_cb <- function(res){
    id <- NULL
    failed <- FALSE
    tryCatch({
      if (res$status != 200){
        err_callback(res)
        return()
      }

      r <- rawToChar(res$content)
      p <- jsonlite::fromJSON(r)
      id <- p$id
    }, error = function(e) {
      print(e)
      err_callback(res)
      failed <<- TRUE
    })

    # If success, we'll have a non-null ID. Otherwise we must have invoked the
    # err_callback.
    if (!failed){
      callback(id)
    }
  }

  curl::curl_fetch_multi(url, handle = handle, done = done_cb, fail = err_callback)

  poll <- function(){
    res <- curl::multi_run(timeout = 0)
    if (res$pending > 0){
      later::later(poll, delay = 0.1)
    }
  }
  poll()

  invisible(NULL)
}
