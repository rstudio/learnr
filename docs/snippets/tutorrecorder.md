tutorial_event_recorder <- function(tutorial_id, tutorial_version, user_id, 
                                    event, data) {
  cat(tutorial_id, " (", tutorial_version, "): ", user_id , "\n", sep = "")
  cat("event: ", event, "\n", sep = "")
}
