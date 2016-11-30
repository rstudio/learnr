options(tutor.event_recorder = function(tutorial, user, label, event, data) {
  cat(tutorial, "(", user, ")\n", sep = "")
  cat(event, ": ", label, "\n", sep = "")
  cat(str(data), "\n")
})