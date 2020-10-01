# Provide exercise feedback
feedback <- function(message, correct, type, location) {
  feedback_validated(list(
    message = message,
    correct = correct,
    type = type,
    location = location
  ))
}

# return feedback if it's valid (with defaults), otherwise throw an error
feedback_validated <- function(feedback) {
  if (!length(feedback)) {
    return(feedback)
  }
  if (!(is.list(feedback) && all(c("message", "correct") %in% names(feedback)))) {
    stop("Feedback must be a list with 'message' and 'correct' fields", call. = FALSE)
  }
  if (!is.character(feedback$message)) {
    stop("The 'message' field of feedback must be a character vector", call. = FALSE)
  }
  if (!is.logical(feedback$correct)) {
    stop("The 'correct' field of feedback must be a logical (i.e., boolean) value", call. = FALSE)
  }
  # Fill in type/location defaults and check their value
  feedback$type <- feedback$type[1] %||% "auto"
  feedback$location <- feedback$location[1] %||% "append"
  feedback_types <- c("auto", "success", "info", "warning", "error", "custom")
  if (!feedback$type %in% feedback_types) {
    stop("Feedback 'type' field must be one of these values: ",
         paste(feedback_types, collapse = ", "), call. = FALSE)
  }
  feedback_locations <- c("append", "prepend", "replace")
  if (!feedback$location %in% feedback_locations) {
    stop("Feedback 'location' field must be one of these values: ",
         paste(feedback_locations, collapse = ", "), call. = FALSE)
  }
  if (feedback$type %in% "auto") {
    feedback$type <- if (feedback$correct) "success" else "error"
  }
  feedback
}

# This function is called to build the html of the feedback
# provided by gradethis
feedback_as_html <- function(feedback, exercise) {

  if (!length(feedback)) {
    return(feedback)
  }
  feedback <- feedback_validated(feedback)
  if (feedback$type %in% "custom") {
    return(div(feedback$message))
  }
  if (feedback$type %in% "error") {
    feedback$type <- "danger"
  }
  if (!feedback$type %in% c("success", "info", "warning", "danger")) {
    stop("Invalid message type specified.", call. = FALSE)
  }
  # Applying custom classes if they exist

  feedback$type <- switch(
    feedback$type,
    success = exercise$options$exercise.success_class %||% "alert-success",
    info = exercise$options$exercise.info_class %||% "alert-info",
    warning = exercise$options$exercise.warning_class %||% "alert-warning",
    danger = exercise$options$exercise.danger_class %||% "alert-danger"
  )

  return(div(
    role = "alert",
    class = paste0("alert ", feedback$type),
    feedback$message
  ))
}

# helper function to create tags for error message
# It is called by learnr when clicking "Run code" & the
# code produced an error
error_message_html <- function(message, exercise) {
  error <- exercise$options$exercise.execution_error_message %||% "There was an error when running your code:"
  class <- sprintf(
    "alert %s",
    exercise$options$exercise.alert_class %||% "alert-red"
  )

  if (
    is.null(exercise$check) &&
    is.null(exercise$code_check)
  ){
    exercise.feedback_show <- TRUE
    exercise.code_show <- TRUE
  } else {
    #Default to TRUE if the option is missing
    exercise.feedback_show <- exercise$options$exercise.feedback_show %||% TRUE
    exercise.code_show <- exercise$options$exercise.feedback_show %||% TRUE
  }



  # The trainer want feedbacks and code (the default)
  if (
    exercise.feedback_show &
    exercise.code_show
  ){
    div(
      class = class,
      role = "alert",
      error,
      tags$pre(
        message
      )

    )
  } else if (
    # The trainer want feedbacks only
    exercise.feedback_show &
    ! exercise.code_show
  ) {
    div(
      class = class,
      role = "alert",
      error
    )
  } else if (
    # The trainer wants code only
    ! exercise.feedback_show &
    exercise.code_show
  ) {
    div(
      tags$pre(
        message
      )
    )
  } else {
    # Not sure what to do there, (i.e the trainer want neither feedback nor code)
    div(
      class = "alert alert-grey",
      role = "alert",
      "Code submitted"
    )
  }
}
