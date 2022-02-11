# {learnr} functions are intended to be written into R Markdown documents,
# but there are certain times when we'd like to warn tutorial authors of
# potential issues without the warning text appearing in the actual tutorial.
# Since we can't ask users to set message = FALSE globally, we have to do our
# own thing. Instead, we have a way to create messages that are automatically
# added to a queue of items when knitting is in progress -- if we're not knitting
# then we just emit the message immediately. Then we take advantage of the
# `tutorial` knit hook that runs before and after each chunk in the tutorial.
# In the after run, we flush the queue and re-signal the condition so that it
# appears in the render console, thus avoiding writing to the tutorial HTML.

.learnr_messages <- local({
  queue <- list()
  list(
    peek = function() {
      if (length(queue)) queue
    },
    flush = function() {
      while(length(queue)) {
        cnd <- queue[[1]]
        if (inherits(cnd, "error")) {
          # throw errors, they're immediate
          rlang::cnd_signal(cnd)
        } else {
          # otherwise report condition as a message, but re-signal warnings
          msg <- rlang::cnd_message(cnd)

          if (inherits(cnd, "warning")) {
            mgs <- paste0("Warning: ", msg)
            rlang::cnd_signal(cnd)
          }

          rlang::inform(msg, class = "learnr_render_message")
        }
        queue[[1]] <<- NULL
      }
    },
    add = function(cnd) {
      queue <<- c(queue, list(cnd))
      invisible(cnd)
    }
  )
})

learnr_render_message <- function(..., level = c("inform", "warn", "abort")) {
  create_cnd <- switch(
    tolower(level),
    inform = rlang::inform,
    warn = rlang::warn,
    abort = rlang::abort
  )
  cnd <- rlang::catch_cnd(create_cnd(paste0(..., "\n"), "learnr_render_message"))

  if (isTRUE(getOption('knitr.in.progress'))) {
    .learnr_messages$add(cnd)
  } else {
    rlang::cnd_signal(cnd)
  }
}

learnr_render_catch <- function(expr, env = rlang::caller_env()) {
  cnd <- tryCatch(
    rlang::eval_bare(expr, env),
    error = identity,
    warning = identity,
    message = identity
  )

  if (!inherits(cnd, "condition")) {
    return(invisible())
  }

  if (isTRUE(getOption('knitr.in.progress'))) {
    .learnr_messages$add(cnd)
  } else {
    rlang::cnd_signal(cnd)
  }
}
