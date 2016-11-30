tutor_event_recorder <- function(tutorial_id, tutorial_version, user_id, 
                                 label, event, data) {
  cat(tutorial_id, " (", tutorial_version, "): ", user_id , "\n", sep = "")
  cat(label, ": ", event, "\n", sep = "")
}
