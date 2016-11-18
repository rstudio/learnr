options(tutor.recorder = function(tutorial, user, label, action, data) {
  cat("[", action, ":", label, "]\n")
  cat(str(data), "\n")
}