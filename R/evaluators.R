
# inline execution evaluator
inline_evaluator <- function(expr, timelimit) {

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
          error_result(e$message)
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
forked_evaluator <- function(expr, timelimit) {

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
          result <<- error_result(result)

        TRUE
      }

      # hit timeout
      else if ((Sys.time() - start_time) >= timelimit) {

        # call cleanup hook
        call_hook("oncleanup", default = default_cleanup)

        # return error result
        result <<- error_result(timeout_error_message())
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
