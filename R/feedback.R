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
  # Applying custom colors if they exist

  feedback$type <- switch(
    feedback$type,
    success = exercise$options$exercise.gradethis_success_color %||% "success",
    info = exercise$options$exercise.gradethis_info_color %||% "info",
    warning = exercise$options$exercise.gradethis_warning_color %||% "warning",
    danger = exercise$options$exercise.gradethis_danger_color %||% "danger"
  )

  return(div(
    role = "alert",
    class = paste0("alert alert-", feedback$type),
    feedback$message
  ))
}

# helper function to create tags for error message
error_message_html <- function(message, exercise) {
  color <- exercise$options$exercise.alert_color %||% "red"
  error <- exercise$options$exercise.execution_error_message %||% "There was an error when running your code:"
  div(
    class = sprintf(
      "alert alert-%s",
      color
    ),
    role = "alert",
    error,
    tags$pre(
      message
    )
  )
}
