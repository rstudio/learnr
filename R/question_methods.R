#' Custom question methods.
#'
#'
#' @description
#' There are five methods used to define a custom question.  Each S3 method
#' should correspond to the `type = TYPE` supplied to the question.
#'
#' * `question_ui_initialize.TYPE(question, value, ...)`
#'
#'     -  Determines how the question is initially displayed to the users. This should return a shiny UI object that can be displayed using [shiny::renderUI]. For example, in the case of `question_ui_initialize.radio`, it returns a [shiny::radioButtons] object. This method will be re-executed if the question is attempted again.
#'
#' * `question_ui_completed.TYPE(question, ...)`
#'
#'     - Determines how the question is displayed after a submission.  Just like `question_ui_initialize`, this method should return an shiny UI object that can be displayed using [shiny::renderUI].
#'
#' * `question_is_valid.TYPE(question, value, ...)`
#'
#'      - This method should return a boolean that determines if the input answer is valid.  Depending on the value, this function enables and disables the submission button.
#'
#' * `question_is_correct.TYPE(question, value, ...)`
#'
#'     - This function should return the output of [correct], [incorrect], or [mark_as]. Each method allows for custom messages in addition to the determination of an answer being correct.  See [correct], [incorrect], or [mark_as] for more details.
#'
#' * `question_ui_try_again <- function(question, value, ...)`
#'
#'     - Determines how the question is displayed to the users while  the "Try again" screen is displayed.  Usually this function will disable inputs to the question, i.e. prevent the student from changing the answer options. Similar to `question_ui_initialize`, this should should return a shiny UI object that can be displayed using [shiny::renderUI].
#'
#'
#'
#'
#' @param question [question] object used
#' @param value user input value
#' @param ... future parameter expansion and custom arguments to be used in dispatched s3 methods.
#' @export
#' @seealso For more information and question type extension examples, please view the `question_type` tutorial: `learnr::run_tutorial("question_type", "learnr")`.
#'
#' @rdname question_methods
question_ui_initialize <- function(question, value, ...) {
  UseMethod("question_ui_initialize", question)
}
#' @export
#' @rdname question_methods
question_ui_try_again <- function(question, value, ...) {
  UseMethod("question_ui_try_again", question)
}
#' @export
#' @rdname question_methods
question_ui_completed <- function(question, value, ...) {
  UseMethod("question_ui_completed", question)
}
#' @export
#' @rdname question_methods
question_is_valid <- function(question, value, ...) {
  UseMethod("question_is_valid", question)
}
#' @export
#' @rdname question_methods
question_is_correct <- function(question, value, ...) {
  UseMethod("question_is_correct", question)
}


question_stop <- function(name, question) {
  classes <- setdiff(class(question), "tutorial_question")
  class_txt <-
    if (length(classes) == 1) {
      classes
    } else{
      paste0("{", paste0(classes, collapse = "/"), "}")
    }
  stop(
    "`", name, ".", class_txt, "(question, ...)` has not been implemented",
    call. = FALSE
  )
}
#' @export
#' @rdname question_methods
question_ui_initialize.default <- function(question, value, ...) {
  question_stop("question_ui_initialize", question)
}
#' @export
#' @rdname question_methods
question_ui_try_again.default <- function(question, value, ...) {
  disable_all_tags(
    question_ui_initialize(question, value, ...)
  )
}
#' @export
#' @rdname question_methods
question_ui_completed.default <- function(question, value, ...) {
  disable_all_tags(
    question_ui_initialize(question, value, ...)
  )
}
#' @export
#' @rdname question_methods
question_is_valid.default <- function(question, value, ...) {
  !is.null(value)
}
#' @export
#' @rdname question_methods
question_is_correct.default <- function(question, value, ...) {
  question_stop("question_is_correct", question)
}


#' Question is correct value
#'
#' Helper method to return
#' @param correct boolean that determines if a question answer is correct
#' @param messages a vector of messages to be displayed.  The type of message will be determined by the `correct` value.
#' @rdname mark_as_correct_incorrect
#' @export
#' @examples
#' # Radio button question implementation of `question_is_correct`
#' question_is_correct.radio <- function(question, value, ...) {
#'   for (ans in question$answers) {
#'     if (as.character(ans$option) == value) {
#'       return(mark_as(
#'         ans$correct,
#'         ans$message
#'       ))
#'     }
#'   }
#'   mark_as(FALSE, NULL)
#' }
correct <- function(messages = NULL) {
  mark_as(correct = TRUE, messages = messages)
}
#' @rdname mark_as_correct_incorrect
#' @export
incorrect <- function(messages = NULL) {
  mark_as(correct = FALSE, messages = messages)
}
#' @rdname mark_as_correct_incorrect
#' @export
mark_as <- function(correct, messages = NULL) {
  checkmate::assert_logical(correct, len = 1, null.ok = FALSE, any.missing = FALSE)
  ret <- list(
    correct = correct,
    messages = messages
  )
  class(ret) <- "learnr_mark_as"
  ret
}



answer_labels <- function(question) {
  lapply(question$answers, `[[`, "label")
}
answer_values <- function(question) {
  ret <- lapply(
    # return the character string input.  This _should_ be unique
    lapply(question$answers, `[[`, "option"),
    as.character
  )
  if (length(unlist(unique(ret))) != length(ret)) {
    stop("Answer `option` values are not unique.  Unique values are required")
  }
  ret
}
