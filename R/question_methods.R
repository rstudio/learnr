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
  stop(
    "`", name, ".{", paste0(class(question), collapse = "/"), "}(question, ...)` has not been implemented",
    .call = FALSE
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
#' @param message a list of messages to be displayed.  The type of message will be determined by the `correct` value.
#' @param ... possible future parameter expansion
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
correct <- function(message = NULL) {
  mark_as(correct = TRUE, message = message)
}
#' @rdname mark_as_correct_incorrect
#' @export
incorrect <- function(message = NULL) {
  mark_as(correct = FALSE, message = message)
}
#' @rdname mark_as_correct_incorrect
#' @export
mark_as <- function(correct, message = NULL) {
  checkmate::assert_logical(correct, len = 1, null.ok = FALSE, any.missing = FALSE)
  checkmate::assert_character(message, len = 1, null.ok = TRUE, any.missing = FALSE)
  ret <- list(correct = correct, message = message)
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





question_ui_initialize.radio <- function(question, value, ...) {
  choice_names <- answer_labels(question)
  choice_values <- answer_values(question)

  radioButtons(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = value %||% FALSE # setting to NULL, selects the first item
  )
}


# question_is_valid.radio <- question_is_valid.default


question_is_correct.radio <- function(question, value, ...) {
  for (ans in question$answers) {
    if (as.character(ans$option) == value) {
      return(mark_as(
        ans$correct,
        ans$message
      ))
    }
  }
  mark_as(FALSE, NULL)
}


question_ui_completed.radio <- function(question, value, ...) {
  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$correct) {
      tag <- " &#10003; "
      tagClass <- "correct"
    } else {
      tag <- " &#10007; "
      tagClass <- "incorrect"
    }
    tags$span(ans$label, HTML(tag), class = tagClass)
  })

  disable_all_tags(
    radioButtons(
      question$ids$answer,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = value
    )
  )
}






question_ui_initialize.checkbox <- function(question, value, ...) {
  choice_names <- answer_labels(question)
  choice_values <- answer_values(question)

  checkboxGroupInput(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = value
  )
}


# question_is_valid.checkbox <- question_is_valid.default


question_is_correct.checkbox <- function(question, value, ...) {

  append_message <- function(x, ans) {
    message <- ans$message
    if (is.null(message)) {
      return(x)
    }
    if (!is.list(message))  {
      message <- list(message)
    }
    if (length(x) == 0) {
      message
    } else {
      append(x, message)
    }
  }

  is_correct <- TRUE
  correct_messages <- list()
  incorrect_messages <- list()

  for (ans in question$answers) {
    ans_is_checked <- as.character(ans$option) %in% value
    submission_is_correct <-
      # is checked and is correct
      (ans_is_checked && ans$correct) ||
      # is not checked and is not correct
      ((!ans_is_checked) && (!ans$correct))

    if (submission_is_correct) {
      # only append messages if the box was checked
      if (ans_is_checked) {
        correct_messages <- append_message(correct_messages, ans)
      }
    } else {
      is_correct <- FALSE
      incorrect_messages <- append_message(incorrect_messages, ans)
    }
  }

  return(mark_as(
    is_correct,
    if (is_correct) correct_messages else incorrect_messages
  ))
}


question_ui_completed.checkbox <- function(question, value, ...) {

  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$correct) {
      tag <- " &#10003; "
      tagClass <- "correct"
    } else {
      tag <- " &#10007; "
      tagClass <- "incorrect"
    }
    tags$span(ans$label, HTML(tag), class = tagClass)
  })

  disable_all_tags(
    checkboxGroupInput(
      question$ids$answer,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = value
    )
  )
}





question_ui_initialize.text <- function(question, value, ...) {
  textInput(
    question$ids$answer,
    label = question$question,
    placeholder = "Enter answer here...",
    value = value
  )
}


question_is_valid.text <- function(question, value, ...) {
  !(is.null(value) || nchar(str_trim(value)) == 0)
}


question_is_correct.text <- function(question, value, ...) {

  if (nchar(value) == 0) {
    showNotification("Please enter some text before submitting", type = "error")
    req(value)
  }

  value <- str_trim(value)

  for (ans in question$answers) {
    if (isTRUE(all.equal(str_trim(ans$label), value))) {
      return(mark_as(
        ans$correct,
        ans$message
      ))
    }
  }
  mark_as(FALSE, NULL)
}

# question_ui_completed.text <- question_ui_completed.default
