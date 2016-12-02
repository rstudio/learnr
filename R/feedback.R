
#' Provide exercise feedback
#' 
#' @param message Feedback message. This can be either plain text or a set of HTML tags
#'   created using the \pkg{htmltools} package.
#' @param correct Was the answer to the exercise correct.
#' @param type Type of feedback. The standard types are "success", "info", "error", and "warning".
#'   Each of these types will result in the feedback text being enclosed in a colored
#'   panel. A value of "auto" will result in "success" when \code{correct == TRUE} and
#'   "error" otherwise. Pass "custom" to pass the feedback message through without any 
#'   decoration.
#' @param location Location of feedback relative to output.
#' 
#' @export
feedback <- function(message,
                     correct,
                     type = c("auto", "success", "info", "warning", "error", "custom"),
                     location = c("append", "prepend", "replace")) {
  
  # resolve type
  type <- match.arg(type)
  if (identical(type, "auto"))
    type <- ifelse(correct, "success", "error")
  
  # return feedback
  structure(class = "tutor_feedback", list(
    message = message,
    correct = correct,
    type = type,
    location = match.arg(location)
  ))
}


#' @importFrom htmltools as.tags
#' @export
as.tags.tutor_feedback <- function(x, ...) {
  if (x$type == "custom") {
    div(x$message)
  }
  else if (x$type %in% c("success", "info", "warning", "error")) {
    if (x$type == "error")
      x$type <- "danger"
    div(class = paste0("alert alert-", x$type), 
        role = "alert", 
        x$message
    )
  }
  else {
    stop("Invalid message type specified.", call. = FALSE)  
  }
}

# helper function to create tags for error message
error_message_html <- function(message) {
  div(class = "alert alert-danger", role = "alert", message)
}






