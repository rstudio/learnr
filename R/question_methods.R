

#' Custom question methods
#'
#' There are four methods used to define a custom question.  Each s3 method should correspond to the `type = TYPE` supplied to the question.
#'
#' \describe{
#'   \item{\code{question_initialize_input.TYPE(question, answer_input, ...)}}{
#'     Determines how the question is initially displayed to the users. This should return an shiny UI object that can be displayed using \code{shiny::\link[shiny]{renderUI}}. In the case of \code{question_initialize_input.radio}, it returns a \code{shiny::\link[shiny]{radioButtons}} object. This method will be re-executed if the question is attempted again.
#'   }
#'   \item{question_completed_input.TYPE(question, ...)}{
#'     Determines how the question is displayed after a submission.  Just like \code{question_initialize_input}, this method should return an shiny UI object that can be displayed using \code{shiny::\link[shiny]{renderUI}}.
#'   }
#'   \item{question_is_valid.TYPE(question, answer_input, ...)}{
#'     This method should return a boolean that determines if the input answer is valid.  Depending on the value, this function enables and disables the submission button.
#'   }
#'   \item{question_is_correct.TYPE(question, answer_input, ...)}{
#'     This function should return the output of \code{learnr::\link{question_is_correct_value}}.  \code{learnr::\link{question_is_correct_value}} allows for custom messages in addition to the determination of an answer being correct.  See \code{\link{question_is_correct_value}} for more details.
#'   }
#' }
#'
#'
#'
#' @param question \code{\link{question}} object used
#' @param answer_input user input value
#' @param ... future parameter expansion and custom arguments to be used in dispatched s3 methods.
#' @export
#' @seealso For more information and question type extension examples, please view the \code{question_type} tutorial: \code{learnr::run_tutorial("question_type", "learnr")}.
#' @rdname question_methods
question_initialize_input <- function(question, answer_input, ...) {
  UseMethod("question_initialize_input", question)
}
#' @export
#' @rdname question_methods
question_completed_input <- function(question, answer_input, ...) {
  UseMethod("question_completed_input", question)
}
#' @export
#' @rdname question_methods
question_is_valid <- function(question, answer_input, ...) {
  UseMethod("question_is_valid", question)
}
#' @export
#' @rdname question_methods
question_is_correct <- function(question, answer_input, ...) {
  UseMethod("question_is_correct", question)
}
#' @export
#' @rdname question_methods
question_try_again_input <- function(question, answer_input, ...) {
  UseMethod("question_try_again_input", question)
}


question_stop <- function(name, question) {
  stop(
    "`", name, ".{", paste0(class(question), collapse = "/"), "}(question, ...)` has not been implemented",
    .call = FALSE
  )
}
question_initialize_input.default <- function(question, answer_input, ...) {
  question_stop("question_initialize_input", question)
}
question_completed_input.default <- function(question, answer_input, ...) {
  disable_all_tags(
    question_initialize_input(question, answer_input)
  )
}
question_is_valid.default <- function(question, answer_input, ...) {
  !is.null(answer_input)
}
question_is_correct.default <- function(question, answer_input, ...) {
  question_stop("question_is_correct", question)
}

question_try_again_input.default <- function(question, answer_input, ...) {
  disable_all_tags(
    question_initialize_input(question, answer_input)
  )
}


#' Question is correct value
#'
#' Helper method to return
#' @param is_correct boolean that determines if a question answer is correct
#' @param messages a list of messages to be displayed.  The type of message will be determined by the `is_correct` value.
#' @param ... possible future parameter expansion
#' @export
#' @examples
#' # Radio button question implementation of `question_is_correct`
#' question_is_correct.radio <- function(question, answer_input, ...) {
#'   if (is.null(answer_input)) {
#'     showNotification("Please select an answer before submitting", type = "error")
#'     req(answer_input)
#'   }
#'   for (ans in question$answers) {
#'     if (as.character(ans$option) == answer_input) {
#'       return(question_is_correct_value(
#'         ans$is_correct,
#'         ans$message
#'       ))
#'     }
#'   }
#'   question_is_correct_value(FALSE, NULL)
#' }
question_is_correct_value <- function(is_correct, messages, ...) {
  if (!is.logical(is_correct)) {
    stop("`is_correct` must be a logical value")
  }
  structure(
    class = "tutorial_question_is_correct_value",
    list(
      is_correct = is_correct,
      messages = messages
    )
  )
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


question_initialize_input.radio <- function(question, answer_input, ...) {
  choice_names <- answer_labels(question)
  choice_values <- answer_values(question)

  radioButtons(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = answer_input %||% FALSE # setting to NULL, selects the first item
  )
}


# question_is_valid.radio <- question_is_valid.default


question_is_correct.radio <- function(question, answer_input, ...) {
  if (is.null(answer_input)) {
    showNotification("Please select an answer before submitting", type = "error")
    req(answer_input)
  }
  for (ans in question$answers) {
    if (as.character(ans$option) == answer_input) {
      return(question_is_correct_value(
        ans$is_correct,
        ans$message
      ))
    }
  }
  question_is_correct_value(FALSE, NULL)
}

question_completed_input.radio <- function(question, answer_input, ...) {
  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$is_correct) {
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
      selected = answer_input
    )
  )
}






question_initialize_input.checkbox <- function(question, answer_input, ...) {
  choice_names <- answer_labels(question)
  choice_values <- answer_values(question)

  checkboxGroupInput(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = answer_input
  )
}


# question_is_valid.checkbox <- question_is_valid.default


# # returns
# list(
#   is_correct = LOGICAL,
#   message = c(CHARACTER)
# )
question_is_correct.checkbox <- function(question, answer_input, ...) {
  if (is.null(answer_input)) {
    showNotification("Please select an answer before submitting", type = "error")
    req(answer_input)
  }

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
    ans_is_checked <- as.character(ans$option) %in% answer_input
    submission_is_correct <-
      # is checked and is correct
      (ans_is_checked && ans$is_correct) ||
      # is not checked and is not correct
      ((!ans_is_checked) && (!ans$is_correct))

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

  return(question_is_correct_value(
    is_correct,
    if (is_correct) correct_messages else incorrect_messages
  ))
}

question_completed_input.checkbox <- function(question, answer_input, ...) {

  choice_values <- answer_values(question)

  # update select answers to have X or √
  choice_names_final <- lapply(question$answers, function(ans) {
    if (ans$is_correct) {
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
      selected = answer_input
    )
  )
}





question_initialize_input.text <- function(question, answer_input, ...) {
  textInput(
    question$ids$answer,
    label = question$question,
    placeholder = "Enter answer here...",
    value = answer_input
  )
}


question_is_valid.text <- function(question, answer_input, ...) {
  !(is.null(answer_input) || nchar(str_trim(answer_input)) == 0)
}
# # returns
# list(
#   is_correct = LOGICAL,
#   message = c(CHARACTER)
# )
question_is_correct.text <- function(question, answer_input, ...) {

  if (is.null(answer_input) || nchar(answer_input) == 0) {
    showNotification("Please enter some text before submitting", type = "error")
    req(answer_input)
  }

  answer_input <- str_trim(answer_input)

  for (ans in question$answers) {
    if (isTRUE(all.equal(str_trim(ans$label), answer_input))) {
      return(question_is_correct_value(
        ans$is_correct,
        ans$message
      ))
    }
  }
  question_is_correct_value(FALSE, NULL)
}

# question_completed_input.text <- question_completed_input.default
