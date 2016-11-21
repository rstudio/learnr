options(tutor.recorder = function(tutorial, user, label, action, data) {
  cat(tutorial, "(", user, ")\n", sep = "")
  cat(action, ": ", label, "\n", sep = "")
  cat(str(data), "\n")
})