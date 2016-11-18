

record <- function(label, action, data) {
  recorder <- getOption("tutor.recorder", default = NULL)
  if (!is.null(recorder)) {
    recorder(tutorial = NULL, 
             user = NULL, 
             label = label,
             action = action, 
             data = data)
  }
  invisible(NULL)
}

record_exercise_hint <- function(label, type = c("solution", "hint"), index) {
  record(label = label,
         action = "exercise_hint",
         data = list(type = type, 
                     index = index))
}

record_exercise_submission <- function(label, 
                                       code, 
                                       output, 
                                       checked = FALSE, 
                                       correct = NA) {
  record(label = label,
         action = "exercise_submission",
         data = list(code = code,
                     output = output,
                     checked = checked,
                     correct = correct))
}

record_question_submission <- function(label, question, answers, correct) {
  record(label = label, 
         action = "question_submission", 
         data = list(question = question, 
                     answers = answers,
                     correct = correct))
}


debug_recorder <- function(label, action, data) {
  cat("[", action, ":", label, "]\n")
  cat(str(data), "\n")
}

