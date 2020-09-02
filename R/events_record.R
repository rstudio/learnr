record_event <- function(session, event, data) {
  recorder <- getOption("tutorial.event_recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial_id = read_request(session, "tutorial.tutorial_id"),
             tutorial_version = read_request(session, "tutorial.tutorial_version"),
             user_id = read_request(session, "tutorial.user_id"),
             event = event,
             data = data)
  }
  invisible(NULL)
}


debug_event_recorder <- function(tutorial_id,
                                 tutorial_version,
                                 user_id,
                                 event,
                                 data) {
  cat(tutorial_id, " (", tutorial_version, "): ", user_id , "\n", sep = "")
  cat("event: ", event, "\n", sep = "")
  utils::str(data)
  cat("\n")
}
