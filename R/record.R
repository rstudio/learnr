
#' Record a user action
#' 
#' Record an action performed by a user in a tutorial (e.g. answering a question,
#' taking a hint, etc.).
#' 
#' @param label Unique label for action
#' @param action Name of action
#' @param data Custom data for action
#' 
#' @export
record <- function(label, action, data) {
  recorder <- getOption("tutor.recorder", default = NULL)
  if (!is.null(recorder))
    recorder(label, action, data)
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

record_question_response <- function(label, question, answers, correct) {
  record(label = label, 
         action = "question_response", 
         data = list(question = question, 
                     answers = answers,
                     correct = correct))
}


debug_recorder <- function(label, action, data) {
  cat("[", action, ":", label, "]\n")
  cat(str(data), "\n")
}

