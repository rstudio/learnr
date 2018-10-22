# TODO-barret Join similar message types line break
# TODO-barret allow for null input$answer
# TODO-barret pass R cmd check
# TODO-barret revert to old params names in question
  ## or deprecate old names and use new names
# TODO-barret allow for messages to be functions
  ## defer to v2
# TODO-barret remove slick quiz library completely
# TODO-barret gut unused R and JS methods from old JS quiz hooks
# TODO-barret documentation of s3 methods for a question
# TODO-barret pass R cmd check



#' Tutorial quiz questions
#'
#' Add interative multiple choice quiz questions to a tutorial.
#'
#' @param text Question or option text
#' @param caption Optional quiz caption (defaults to "Quiz")
#' @param type Type of quiz question. Typically this can be automatically determined
#'   based on the provided answers Pass \code{"single"} to indicate that even though
#'   multiple correct answers are specified that inputs which include only one correct
#'   answer are still correct. Pass \code{"multiple"} to force the use of checkboxes
#'   (as opposed to radio buttons) even though only once correct answer was provided.
#' @param correct For \code{question}, text to print for a correct answer (defaults
#'   to "Correct!"). For \code{answer}, a boolean indicating whether this answer is
#'   correct.
#' @param incorrect Text to print for an incorrect answer (defaults to "Incorrect.")
#' @param message Additional message to display along with correct/incorrect feedback.
#' @param ... One or more questions or answers
#' @param allow_retry Allow retry for incorrect answers.
#' @param random_answer_order Display answers in a random order.
#'
#' @examples
#' \dontrun{
#' question("What number is the letter A in the alphabet?",
#'   answer("8"),
#'   answer("14"),
#'   answer("1", correct = TRUE),
#'   answer("23"),
#'   incorrect = "See [here](https://en.wikipedia.org/wiki/English_alphabet) and try again.",
#'   allow_retry = TRUE
#' )
#'
#' question("Where are you right now? (select ALL that apply)",
#'   answer("Planet Earth", correct = TRUE),
#'   answer("Pluto"),
#'   answer("At a computing device", correct = TRUE),
#'   answer("In the Milky Way", correct = TRUE),
#'   incorrect = paste0("Incorrect. You're on Earth, ",
#'                      "in the Milky Way, at a computer.")
#' )
#' }
#'
#' @name quiz
#' @export
quiz <- function(..., caption = "Quiz") {

  # create table rows from questions
  index <- 1
  questions <- lapply(list(...), function(question) {
    if (!is.null(question$label)) {
      question$label <- paste(question$label, index, sep="-")
      index <<- index + 1
    }
    question
  })

  structure(
    class = "tutorial_quiz", 
    list(
      caption = if(!is.null(caption)) quiz_text(caption),
      questions = questions
    )
  )
}


#' @rdname quiz
#' @import shiny
#' @export
question <- function(text,
                     ...,
                     type = c("auto", "single", "multiple", "radio", "checkbox", "text"),
                     correct_message = random_praise(),
                     try_again_message = random_encouragement(),
                     incorrect_message = "Incorrect",
                     post_message = NULL,
                     submit_button = "Submit Answer",
                     try_again_button = "Try Again",
                     allow_retry = FALSE,
                     random_answer_order = FALSE
                   ) {


  # one time tutor initialization
  initialize_tutorial()

  # capture/validate answers
  answers <- list(...)
  lapply(answers, function(answer) {
    if (!inherits(answer, "tutorial_quiz_answer"))
      stop("Object which is not an answer passed to question function")
  })

  # verify chunk label if necessary
  verify_tutorial_chunk_label()

  total_correct <- sum(vapply(answers, function(ans) { ans$is_correct }, logical(1)))
  if (total_correct == 0) {
    stop("At least one correct answer must be supplied")
  }
    
  ## no partial matching for s3 methods
  # type <- match.arg(type)
  if (missing(type)) {
    type <- "auto"
  }
  if (isTRUE(all.equal(type, "auto"))) {
    if (total_correct > 1) {
      type <- "multiple"
    } else {
      type <- "single"
    }
  }
  if (length(type) == 1) {
    type <- switch(type, 
      "single" = "radio",
      "multiple" = "checkbox",
      # allows for s3 methods
      type
    )
  }
  
  q_id <- random_question_id()
  ns <- NS(q_id)

  return(
    structure(
      class = c(type, "tutorial_question"),
      list(
        type = type,
        label = knitr::opts_current$get('label'),
        question = quiz_text(text),
        answers = answers,
        button_labels = list(
          correct = "Correct!",
          incorrect = "Incorrect",
          submit = quiz_text(submit_button),
          try_again = quiz_text(try_again_button)
        ),
        messages = list(
          correct = quiz_text(correct_message),
          try_again = quiz_text(try_again_message),
          incorrect = quiz_text(incorrect_message),
          post_message = quiz_text(post_message)
        ),
        ids = list(
          action_button = ns("action_button"),
          answer = ns("answer"),
          question = q_id,
          answer_container = ns("answer_container"),
          action_button_container = ns("action_button_container"),
          message_container = ns("message_container")
        ),
        random_answer_order = random_answer_order,
        allow_retry = allow_retry
      )
    )
  )

}

#' @rdname quiz
#' @export
answer <- function(text, correct = FALSE, message = NULL) {
  if (!is.character(text)) {
    stop("Non-string `text` values are not allowed as an answer")
  }
  structure(class = "tutorial_quiz_answer", list(
    id = random_answer_id(),
    option = as.character(text),
    label = quiz_text(text),
    is_correct = isTRUE(correct),
    message = quiz_text(message)
  ))
}

# render markdown (including equations) for quiz_text
quiz_text <- function(text) {
  if (inherits(text, "html")) {
    return(text)
  }
  if (!is.null(text)) {
    # convert markdown
    md <- markdown::markdownToHTML(
      text = text,
      options = c("use_xhtml", "fragment_only", "mathjax"),
      extensions = markdown::markdownExtensions(),
      fragment.only = TRUE,
      encoding = "UTF-8"
    )
    # remove leading and trailing paragraph
    md <- sub("^<p>", "", md)
    md <- sub("</p>\n?$", "", md)
    HTML(md)
  }
  else {
    NULL
  }
}


# used to print the html for a quiz
quiz_html <- function(id, style, class, ...) {
  htmltools::HTML(sprintf('
<div id="%s" style="%s", class = "%s">
<div class="panel panel-default">
<div class="panel-body quizArea">
</div>
</div>
</div>
', id, style, class))
}


#
#
#
#
#
# text_box_quiz_html <- function(id, style, class, ...) {
#   htmltools::HTML(glue::glue_data(
#     list(id = id, style = style, class = class),
# '
# <div id="{id}" style="{style}", class = "{class}">
# <div class="panel panel-default">
# <div class="panel-body quizArea">
# </div>
# </div>
# </div>
# '
#   ))
# }


# quiz_to_shiny <- function(quiz) {
#
#   lapply(quiz$questions, question_to_shiny)
# }

random_question_id <- function() {
  random_id("lnr_ques")
}
random_answer_id <- function() {
  random_id("lnr_ans")
}
#' @importFrom stats runif
random_id <- function(txt) {
  paste0(txt, "_", as.hexmode(floor(runif(1, 1, 16^7))))
}

shuffle <- function(x) {
  sample(x, length(x))
}


knit_print.tutorial_question <- function(question, ...) {

  ui <- question_module_ui(question$ids$question)
  
  # knitr::set_chunkattr(echo = FALSE)
  rmarkdown::shiny_prerendered_chunk(
    'server',
    sprintf(
      'learnr:::question_prerendered_chunk(%s)',
      dput_to_string(question)
    )
  )
  
  # regular knit print the UI
  knitr::knit_print(ui)
}
knit_print.tutorial_quiz <- function(quiz, ...) {
  caption_tag <- if (!is.null(quiz$caption)) {
    list(knitr::knit_print(
      tags$div(class = "panel-heading tutorial-panel-heading", quiz$caption)
    ))
  }
  
  append(
    caption_tag,
    lapply(quiz$questions, knitr::knit_print)
  )
}




# question_methods <- function(question, ids, ...) {
#   # class(question) <- c(question$type, class(question))
#   dispatch <- "tmp_obj"
#   class(dispatch) <- question$type
#   UseMethod("question_methods", dispatch)
# }
# question_methods.default <- function(question, ids, ...) {
#   stop("`question_methods.", question$type, "(question, ids, ...)` has not been implemented")
# }



# returns shinyUI component
question_initialize_input <- function(question, answer_input, ...) {
  UseMethod("question_initialize_input", question)
}
question_completed_input <- function(question, answer_input, ...) {
  UseMethod("question_completed_input", question)
}
question_is_valid <- function(question, answer_input, ...) {
  UseMethod("question_is_valid", question)
}
# # uses req() to determine if results are ok
# # returns
# list(
#   is_correct = LOGICAL,
#   message = CHARACTER
# )
question_is_correct <- function(question, answer_input, ...) {
  UseMethod("question_is_correct", question)
}


question_stop <- function(name, question) {
  stop(
    "`", name, ".", class(question[1]), "(question, ...)` has not been implemented", 
    .call = FALSE
  )
}
question_initialize_input.default <- function(question, answer_input, ...) {
  question_stop("question_initialize_input", question)
}
question_completed_input.default <- function(question, ...) {
  question_stop("question_completed_input", question)
}
question_is_valid.default <- function(question, answer_input, ...) {
  question_stop("question_is_valid", question)
}
question_is_correct.default <- function(question, answer_input, ...) {
  question_stop("question_is_correct", question)
}


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

question_is_valid.radio <- function(question, answer_input, ...) {
  !is.null(answer_input)
}

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

  radioButtons(
    question$ids$answer,
    label = question$question,
    choiceValues = choice_values,
    choiceNames = choice_names_final,
    selected = answer_input
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

question_is_valid.checkbox <- function(question, answer_input, ...) {
  !is.null(answer_input)
}

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

  checkboxGroupInput(
    question$ids$answer,
    label = question$question,
    choiceValues = choice_values,
    choiceNames = choice_names_final,
    selected = answer_input
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
  !(is.null(answer_input) || nchar(answer_input) == 0)
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

question_completed_input.text <- function(question, answer_input, ...) {
  textInput(
    question$ids$answer,
    label = question$question,
    value = answer_input
  )
}



retrieve_all_question_submissions <- function(session) {
  state_objects <- get_all_state_objects(session, exercise_output = FALSE)

  # create submissions from state objects
  submissions <- submissions_from_state_objects(state_objects)
  
  submissions
}

retrieve_question_submission_answer <- function(session, question_label) {
  question_label <- as.character(question_label)
  
  for (submission in retrieve_all_question_submissions(session)) {
    if (identical(as.character(submission$id), question_label)) {
      return(submission$data$answers)
    }
  }
  return(NULL)
}




question_prerendered_chunk <- function(question, ...) {
  callModule(
    question_module_server,
    question$ids$question,
    question = question
  )
  invisible(TRUE)
}

question_module_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("answer_container")),
    uiOutput(ns("message_container")),
    uiOutput(ns("action_button_container"))
  )
}

question_module_server <- function(
  input, output, session,
  question
) {
  
  output$answer_container <- renderUI({ tags$label(class="control-label", "Loading...") })
  output$action_button_container <- renderUI({
    tags$input(type = "button", value = "Loading...", class="btn btn-info", disabled = NA)
  })
  
  observeEvent(
    req(session$userData$learnr_state() == "restored"), 
    once = TRUE, 
    {
      question_module_server_impl(input, output, session, question)
    }
  )
}

question_module_server_impl <- function(
  input, output, session,
  question
) {

  ns <- getDefaultReactiveDomain()$ns
  
  # only set when a submit button has been pressed
  # (or reset when try again is hit)
  # (or set when restoring)
  submitted_answer <- reactiveVal(NULL, label = "submitted_answer")
  
  is_correct_info <- reactive(label = "is_correct_info", {
    # question has not been submitted
    if (is.null(submitted_answer())) return(NULL)
    # find out if answer is right
    ret <- question_is_correct(question, submitted_answer())
    if (!inherits(ret, "tutorial_question_is_correct_value")) {
      stop("`question_is_correct(question, input$answer)` must return a result from `question_is_correct_value`")
    }
    ret
  })
  
  # should present all messages?
  is_done <- reactive(label = "is_done", {
    if (is.null(is_correct_info())) return(NULL)
    (!isTRUE(question$allow_retry)) || is_correct_info()$is_correct
  })

  
  button_type <- reactive(label = "button type", {
    if (is.null(submitted_answer())) {
      "submit"
    } else {
      # is_correct_info() should be valid
      if (is.null(is_correct_info())) {
        stop("`is_correct_info()` is `NULL` in a place it shouldn't be")
      }
      
      # update the submit button label
      if (is_correct_info()$is_correct) {
        "correct"
      } else {
        # not correct
        if (isTRUE(question$allow_retry)) {
          # not correct, but may try again
          "try_again"
        } else {
          # not correct and can not try again
          "incorrect"
        }
      }
    }
  })
  
  # disable / enable for every input$answer change
  answer_is_valid <- reactive(label = "answer_is_valid", {
    if (is.null(submitted_answer())) {
      question_is_valid(question, input$answer)
    } else {
      question_is_valid(question, submitted_answer())
    }
  })

  init_question <- function(restoreValue = NULL) {
    if (question$random_answer_order) {
      question$answers <<- shuffle(question$answers)
    }
    submitted_answer(restoreValue)
  }
  
  # restore past submission
  #  If no prior submission, it returns NULL
  past_submission_answer <- retrieve_question_submission_answer(session, question$label)
  # initialize like normal... nothing has been submitted
  #   or
  # initialize with the past answer
  #  this should cascade throughout the app to display correct answers and final outputs
  init_question(past_submission_answer)
  

  output$action_button_container <- renderUI({
    question_button_label(
      question,
      button_type(),
      answer_is_valid()
    )
  })

  output$message_container <- renderUI({
    req(!is.null(is_correct_info()), !is.null(is_done()))

    question_messages(
      question, 
      messages = is_correct_info()$messages, 
      is_correct = is_correct_info()$is_correct, 
      is_done = is_done()
    )
  })
  
  output$answer_container <- renderUI({
    if (is.null(submitted_answer())) {
      # has not submitted, show regular answers
      return(
        question_initialize_input(question, submitted_answer())
      )
    } else {
      # has submitted
      if (is.null(is_done())) return(NULL)
      if (is_done()) {
        # if the question is 'done', display the final input ui and disable everything
        return(
          disable_all_tags(
            question_completed_input(question, submitted_answer())
          )
        )
      } else {
        # if the question is NOT 'done', disable the current UI 
        #   until it is reset with the try again button
        return(
          disable_all_tags(
            question_initialize_input(question, submitted_answer())
          )
        )
      }
    }
  })
  
  
  observeEvent(input$action_button, {

    if (button_type() == "try_again") {
      init_question(NULL)
      return()
    }

    submitted_answer(input$answer)
  
    # submit question to server
    question_submission_event(
      session = session,
      label = as.character(question$label),
      question = as.character(question$question),
      answers = as.character(input$answer),
      correct = is_correct_info()$is_correct
    )

  })
}



disable_element_fn <- function(ele) {
  tagAppendAttributes(
    ele,
    class = "disabled",
    disabled = NA
  )
}
disable_tags <- function(ele, selector) {
  mutate_tags(ele, selector, disable_element_fn)
}
disable_all_tags <- function(ele) {
  mutate_tags(ele, "*", disable_element_fn)
}



question_button_label <- function(question, label_type = "submit", is_valid = TRUE) {
  label_type <- match.arg(label_type, c("submit", "try_again", "correct", "incorrect"))
  button_label <- question$button_labels[[label_type]]
  is_valid <- isTRUE(is_valid)
  
  default_class <- "btn-primary"
  warning_class <- "btn-warning"
  
  if (label_type == "submit") {
    button <- actionButton(question$ids$action_button, button_label, class = default_class)
    if (!is_valid) {
      button <- disable_all_tags(button)
    }
    button
  } else if (label_type == "try_again") {
    mutate_tags(
      actionButton(question$ids$action_button, button_label, class = warning_class),
      paste0("#", question$ids$action_button), 
      function(ele) {
        ele$attribs$class <- str_remove(ele$attribs$class, "\\s+btn-default")
        ele
      }
    )
  } else if (
    label_type == "correct" || 
    label_type == "incorrect"
  ) {
    NULL
  }
}

question_messages <- function(question, messages, is_correct, is_done) {

  # Always display the incorrect, correct, or try again messages
  default_message <-
    if (is_correct) {
      question$messages$correct
    } else {
      # not correct
      if (is_done) {
        question$messages$incorrect
      } else {
        question$messages$try_again
      }
    }
  
  if (!is.null(messages) && !is.list(messages)) {
    messages <- list(messages)
  }

  # display the default messages first
  if (!is.null(default_message)) {
    messages <- append(list(default_message), messages)
  }

  # get regular message
  if (is.null(messages)) {
    message_alert <- NULL
  } else {
    alert_class <- if (is_correct) "alert-success" else "alert-danger"
    message_alert <- lapply(messages, function(message) {
      tags$div(
        class = paste0("alert ", alert_class),
        message
      )
    })
  }

  # get post question message only if the question is done
  if (isTRUE(is_done) && !is.null(question$messages$post_message)) {
    post_alert <- tags$div(
      class = "alert alert-info",
      question$messages$post_message
    )
  } else {
    post_alert <- NULL
  }

  # set UI message
  if (is.null(message_alert) && is.null(post_alert)) {
    NULL
  } else {
    tags$div(message_alert, post_alert)
  }
}
















.praise <- c(
  "Absolutely fabulous!",
  "Amazing!",
  "Awesome!",
  "Beautiful!",
  "Bravo!",
  "Cool job!",
  "Delightful!",
  "Excellent!",
  "Fantastic!",
  "Great work!",
  "I couldn't have done it better myself.",
  "Impressive work!",
  "Lovely job!",
  "Magnificent!",
  "Nice job!",
  "Out of this world!",
  "Resplendent!",
  "Smashing!",
  "Someone knows what they're doing :)",
  "Spectacular job!",
  "Splendid!",
  "Success!",
  "Super job!",
  "Superb work!",
  "Swell job!",
  "Terrific!",
  "That's a first-class answer!",
  "That's glorious!",
  "That's marvelous!",
  "Very good!",
  "Well done!",
  "What first-rate work!",
  "Wicked smaht!",
  "Wonderful!",
  "You aced it!",
  "You rock!",
  "You should be proud.",
  ":)"
)

  # Encouragement messages
.encourage <- c(
  "Please try again.",
  "Give it another try.",
  "Let's try it again.",
  "Try it again; next time's the charm!",
  "Don't give up now, try it one more time.",
  "But no need to fret, try it again.",
  "Try it again. I have a good feeling about this.",
  "Try it again. You get better each time.",
  "Try it again. Perseverence is the key to success.",
  "That's okay: you learn more from mistakes than successes. Let's do it one more time."
)

random_praise <- function() {
  paste0("Correct! ", sample(.praise, 1))
}
random_encouragement <- function() {
  sample(.encourage, 1)
}




str_trim <- function(x) {
  sub(
    "\\s$", "", 
    sub(
      "^\\s+", "", 
      as.character(x)
    )
  )
}

if_no_match_return_null <- function(x) {
  if (length(x) == 0) {
    NULL
  } else {
    x
  }
}
str_match <- function(x, pattern) {
  if_no_match_return_null(
    regmatches(x, regexpr(pattern, x))
  )
  
}
str_match_all <- function(x, pattern) {
  if_no_match_return_null(
    regmatches(x, gregexpr(pattern, x))[[1]]
  )
}
str_replace <- function(x, pattern, replacement) {
  if (is.null(x)) return(NULL)
  sub(pattern, replacement, x)
}
str_remove <- function(x, pattern) {
  str_replace(x, pattern, "")
}

# only handles id and classes
as_selector <- function(selector) {
  if (inherits(selector, "shiny_selector") || inherits(selector, "shiny_selector_list")) {
    return(selector)
  }
    
  # make sure it's a trimmed string
  selector <- str_trim(selector)
  
  # yell if there is a comma
  if (grepl(",", selector, fixed = TRUE)) {
    stop("Do not know how to handle comma separatated selector values")
  }

  # if it contains multiple elements, recurse
  if (grepl(" ", selector)) {
    selector <- lapply(strsplit(selector, "\\s+"), as_selector)
    selector <- structure(class = "shiny_selector_list", selector)
    return(selector)
  }
  
  match_everything <- isTRUE(all.equal(selector, "*"))
  
  element <- str_match(selector, "^([^#.]+)")
  selector <- str_remove(selector, "^[^#.]+")
  
  id <- str_remove(str_match(selector, "^#([^.]+)"), "#")
  selector <- str_remove(selector, "^#[^.]+")
  
  classes <- str_remove(str_match_all(selector, "\\.([^.]+)"), "^\\.")
  
  structure(class = "shiny_selector", list(
    element = element,
    id = id, 
    classes = classes,
    match_everything = match_everything
  ))
}

as_selector_list <- function(selector) {
  selector <- as_selector(selector)
  if (inherits(selector, "shiny_selector")) {
    selector <- structure(class = "shiny_selector_list", list(selector))
  }
  selector
}

format.shiny_selector <- function(x, ...) {
  if (x$match_everything) {
    paste0("* // match everything")
  } else {
    paste0(x$element, if (!is.null(x$id)) paste0("#", x$id), paste0(".", x$classes, collapse = ""))
  }
}
format.shiny_selector_list <- function(x, ...) {
  paste0(unlist(lapply(x, format, ...)), collapse = " ")
}

print.shiny_selector <- function(x, ...) {
  cat("// css selector\n")
  cat(format(x, ...), "\n")
}
print.shiny_selector_list <- function(x, ...) {
  cat("// css selector list\n")
  cat(format(x, ...), "\n")
}














mutate_tags <- function(ele, selector, fn, ...) {
  UseMethod("mutate_tags", ele)
}
mutate_tags.default <- function(ele, selector, fn, ...) {
  stop("`mutate_tags.", class(ele)[1], "(x, selector, ...)` is not implemented")
}

# no-ops for basic types
mutate_tags.NULL <- function(ele, selector, fn, ...) { ele }
mutate_tags.character <- function(ele, selector, fn, ...) { ele }
mutate_tags.numeric <- function(ele, selector, fn, ...) { ele }
mutate_tags.logical <- function(ele, selector, fn, ...) { ele }
mutate_tags.list <- function(ele, selector, fn, ...) { lapply(ele, mutate_tags, selector, fn, ...) }


mutate_tags.shiny.tag <- function(ele, selector, fn, ...) {
  if (inherits(selector, "character")) {
    # if there is a set of selectors
    if (grepl(",", selector)) {
      selectors <- strsplit(selector, ",")[[1]]
      # serially mutate the tags for each indep selector
      for (selector_i in selectors) {
        ele <- mutate_tags(ele, selector_i, fn, ...)
      }
      return(ele)
    }
  }
  
  # make sure it's a selector
  selector <- as_selector_list(selector)
  # grab the first element
  cur_selector <- selector[[1]]
  
  is_match <- TRUE
  if (!cur_selector$match_everything) {
    # match on element
    if (is_match && !is.null(cur_selector$element)) {
      is_match <- ele$name == cur_selector$element
    }
    # match on id
    if (is_match && !is.null(cur_selector$id)) {
      is_match <- (ele$attribs$id %||% "") == cur_selector$id
    }
    # match on class values
    if (is_match && !is.null(cur_selector$classes)) {
      is_match <- all(strsplit(ele$attribs$class %||% "", " ")[[1]] %in% cur_selector$classes)
    }
    
    # if it is a match, drop a selector
    if (is_match) {
      selector <- selector[-1]
    }
  }
  
  # if there are children and remaining selectors, recurse through
  if (length(selector) > 0 && length(ele$children) > 0) {
    for (i in seq_along(ele$children)) {
      ele$children[[i]] <- mutate_tags(ele$children[[i]], selector, fn, ...)
    }
  }
  
  # if it was a match
  if (is_match) {
    if (
      # it is a "leaf" match
      length(selector) == 0 ||
      # or should match everything
      cur_selector$match_everything
    ) {
      # update it
      ele <- fn(ele, ...)
    }
  }
    
  # return the updated element
  ele
}
