# TODO - make messages functions
# TODO-barret remove shinyjs





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
    if (!is.null(question$x$label)) {
      question$x$label <- paste(question$x$label, index, sep="-")
      index <<- index + 1
    }
    question
  })

  questions
}


#' @rdname quiz
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
  if (type == "auto") {
    if (total_correct > 1) {
      type <- "multiple"
    } else {
      type <- "single"
    }
  }
  type <- switch(type, 
    "single" = "radio",
    "multiple" = "checkbox",
    # allows for s3 methods
    type
  )
  
  q_id <- random_question_id()
  ns <- NS(q_id)

  return(
    structure(
      class = c(type, "question"),
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

  # # if (type == "single")
  # #   question$select_any <- TRUE
  # # if (type == "multiple")
  # #   question$force_checkbox <- TRUE
  # 
  # # # save all state/options into "x"
  # # x <- list()
  # # x$question <- quiz_text(text)
  # # x$answers <- answers
  # # x$label <- knitr::opts_current$get('label')
  # # x$skipStartButton <- TRUE # no start
  # # x$perQuestionResponseAnswers <- TRUE
  # # x$perQuestionResponseMessaging <- TRUE
  # # x$preventUnanswered <- TRUE
  # # x$displayQuestionCount <- FALSE
  # # x$displayQuestionNumber <- FALSE
  # # x$disableRanking <- TRUE
  # # x$nextQuestionText <- ""
  # # x$checkAnswerText <- "Submit Answer"
  # # x$allowRetry <- allow_retry
  # # x$randomSortAnswers = random_answer_order
  # # x$json <- list(
  # #   info = list(
  # #     name = "",
  # #     main = ""
  # #   ),
  # #   questions = list(question)
  # # )
  # 
  # # define dependencies
  # dependencies <- list(
  #   rmarkdown::html_dependency_jquery(),
  #   rmarkdown::html_dependency_bootstrap(theme = "default"),
  #   bootbox_html_dependency(),
  #   localforage_html_dependency(),
  #   tutorial_html_dependency(),
  #   tutorial_autocompletion_html_dependency(),
  #   tutorial_diagnostics_html_dependency(),
  #   htmltools::htmlDependency(
  #     name = "slickquiz",
  #     version = "1.5.20",
  #     src = html_dependency_src("htmlwidgets", "lib", "slickquiz"),
  #     script = "js/slickQuiz.js",
  #     stylesheet = c("css/slickQuiz.css", "css/slickQuizTutorial.css")
  #   )
  # )
  # 
  # # create widget
  # htmlwidgets::createWidget(
  #   name = 'quiz',
  #   x = x,
  #   width = "100%",
  #   height = "auto",
  #   dependencies = dependencies,
  #   sizingPolicy = htmlwidgets::sizingPolicy(knitr.figure = FALSE,
  #                                            knitr.defaultWidth = "100%",
  #                                            knitr.defaultHeight = "auto",
  #                                            viewer.defaultWidth = "100%",
  #                                            viewer.defaultHeight = "auto"),
  #   package = 'learnr'
  # )

}

#' @rdname quiz
#' @export
answer <- function(text, correct = FALSE, message = NULL) {
  if (!is.character(text)) {
    stop("Non-string `text` values are not allowed as an answer")
  }
  structure(class = "tutorial_quiz_answer", list(
    id = random_answer_id(),
    option = text,
    label = quiz_text(text),
    is_correct = isTRUE(correct),
    message = quiz_text(message)
  ))
}

# render markdown (including equations) for quiz_text
quiz_text <- function(text) {
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
random_id <- function(txt) {
  paste0(txt, "_", as.hexmode(floor(runif(1, 1, 16^7))))
}

shuffle <- function(x) {
  sample(x, length(x))
}

question_to_shiny <- function(question) {

  ui <- question_module_ui(question$ids$question)
  
  # knitr::set_chunkattr(echo = FALSE)
  rmarkdown::shiny_prerendered_chunk(
    'server',
    sprintf(
      'learnr:::question_prerendered_chunk(%s)',
      dput_to_string(question)
    )
  )
  
  ui
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
question_initialize_input <- function(question, ...) {
  UseMethod("question_initialize_input", question)
}
question_completed_input <- function(question, ...) {
  UseMethod("question_completed_input", question)
}
question_is_valid <- function(question, answer_input, ...) {
  UseMethod("question_is_valid", question)
}
# # uses req() to determine if results are ok
# # returns
# list(
#   is_correct = LOGICAL,
#   message = CHARACTER,
#   selected = LIST(ANSWER)
# )
question_is_correct <- function(question, answer_input, ...) {
  UseMethod("question_is_correct", question)
}
# css selector of elements to disable
question_disable_selector <- function(question, ...) {
  UseMethod("question_disable_selector", question)
}


question_stop <- function(name, question) {
  stop(
    "`", name, ".", class(question[1]), "(question, ...)` has not been implemented", 
    .call = FALSE
  )
}
question_initialize_input.default <- function(question, ...) {
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
question_disable_selector.default <- function(question, ...) {
  question_stop("question_disable_selector", question)
}


question_initialize_input.radio <- function(question, ...) {
  choice_names <- lapply(question$answers, `[[`, "label")
  choice_values <- lapply(question$answers, `[[`, "id")

  shiny::radioButtons(
    question$ids$answer,
    label = question$question,
    choiceNames = choice_names,
    choiceValues = choice_values,
    selected = FALSE
  )
}


question_is_valid.radio <- function(question, answer_input, notify, ...) {
  !is.null(answer_input)
}

question_is_correct.radio <- function(question, answer_input, ...) {
  if (is.null(answer_input)) {
    showNotification("Please select an answer before submitting", type = "error")
    req(answer_input)
  }
  for (ans in question$answers) {
    if (ans$id == answer_input) {
      return(list(
        is_correct = ans$is_correct,
        messages = ans$message,
        selected = list(
          ans
        )
      ))
    }
  }
  return(list(is_correct = FALSE, messages = NULL, selected = list()))
}

question_completed_input.radio <- function(question, answer_input, ...) {
  choice_values <- lapply(question$answers, `[[`, "id")

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

  shiny::radioButtons(
    question$ids$answer,
    label = question$question,
    choiceValues = choice_values,
    choiceNames = choice_names_final,
    selected = answer_input
  )
}

disable_selector <- function(question, ...) {
  paste0("#", question$ids$answer, " .radio")
}






question_methods.checkbox <- function(question, ids, ...) {

  initialize_input <- function(answers) {
    choice_names <- lapply(answers, function(ans) {
      ans$label
    })
    choice_values <- lapply(answers, function(ans) {
      ans$id
    })

    shiny::checkboxGroupInput(
      ids$answer,
      label = question$question,
      choiceNames = choice_names,
      choiceValues = choice_values,
      selected = FALSE
    )
  }

  # # returns
  # list(
  #   is_correct = LOGICAL,
  #   message = c(CHARACTER)
  # )
  is_correct <- function(answer_input, answers) {
    is_correct <- TRUE

    correct_messages <- c()
    incorrect_messages <- c()

    for (ans in answers) {
      ans_is_checked <- ans$id %in% answer_input
      submission_is_correct <-
        (ans_is_checked && ans$is_correct) ||
        ((!ans_is_checked) && (!ans$is_correct))

      if (submission_is_correct) {
        # only append messages if the box was checked
        if (ans_is_checked) {
          correct_messages <- append(correct_messages, ans$message)
        }
      } else {
        is_correct <- FALSE
        incorrect_messages <- append(incorrect_messages, ans$message)
      }
    }

    return(list(
      is_correct = is_correct,
      messages = if (is_correct) correct_messages else incorrect_messages
    ))
  }

  completed_input <- function(answer_input, answers) {

    choice_values <- lapply(answers, `[[`, "id")

    # update select answers to have X or √
    choice_names_final <- lapply(answers, function(ans) {
      if (ans$is_correct) {
        tag <- " &#10003; "
        tagClass <- "correct"
      } else {
        tag <- " &#10007; "
        tagClass <- "incorrect"
      }
      tags$span(ans$label, HTML(tag), class = tagClass)
    })

    shiny::checkboxGroupInput(
      ids$answer,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = answer_input
    )
  }

  is_valid <- function(answer_input) {
    if (is.null(answer_input)) {
      showNotification("Please select an answer before submitting", type = "error")
      req(answer_input)
    }
  }

  disable_selector <- function() {
    paste0("#", ids$answer, " .checkbox")
  }

  list(
    initialize_input = initialize_input,
    is_correct = is_correct,
    completed_input = completed_input,
    is_valid = is_valid,
    disable_selector = disable_selector
  )
}




question_methods.text <- function(question, ids, ...) {
  ns <- shiny::NS(ids$question)
  
  initialize_input <- function(answers) {
    shiny::textInput(
      ids$answer,
      label = question$question,
      placeholder = "Enter answer here..."
    )
  }

  # # returns
  # list(
  #   is_correct = LOGICAL,
  #   message = c(CHARACTER)
  # )
  is_correct <- function(answer_input, answers) {

    trim <- function(x) {
      x %>%
        as.character() %>%
        sub("^\\s+", "", .) %>%
        sub("\\s$", "", .)
    }

    answer_input <- trim(answer_input)

    for (ans in answers) {
      if (isTRUE(all.equal(trim(ans$label), answer_input))) {
        return(list(
          is_correct = ans$is_correct,
          messages = ans$message
        ))
      }
    }
    return(list(is_correct = FALSE, messages = NULL))
  }

  completed_input <- function(answer_input, answers) {
    shiny::textInput(
      ids$answer,
      label = question$question,
      value = answer_input
    )
  }

  is_valid <- function(answer_input) {
    if (is.null(answer_input) || nchar(answer_input) == 0) {
      showNotification("Please enter some text before submitting", type = "error")
      req(answer_input)
    }
  }

  disable_selector <- function() {
    paste0("#", ids$answer)
  }
  
  list(
    initialize_input = initialize_input,
    is_correct = is_correct,
    completed_input = completed_input,
    is_valid = is_valid,
    disable_selector = disable_selector
  )
}




# # TODO-shiny app to shiny module
# # return a call to the module UI
#
# question_ui <- function(id, ..., extra_args) {
#   ns <- NS(id)
#
#   tagList(
#     ...
#   )
# }
#
# question_mod <- function(input, output, session) {
#
# }
#
# question_radio_to_shiny2 <- function(question) {
#   q_id <- random_question_id()
#   callModule(question_mod, q_id)
#   question_ui(q_id)
# }


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
    # TODO as html dependency
    shiny::includeCSS(system.file("htmlwidgets/lib/slickquiz/css/slickQuiz.css", package = "learnr")),
    shiny::includeCSS(system.file("htmlwidgets/lib/slickquiz/css/slickQuizTutorial.css", package = "learnr")),
    # shiny::uiOutput(ns("shinyjs_container")),  # Set up shinyjs
    # shiny::textInput(ns("barret"), "barret", "barret", 50),
    shiny::uiOutput(ns("answer_container")),
    shiny::uiOutput(ns("message_container")),
    shiny::uiOutput(ns("action_button_container"))
  )
}

question_module_server <- function(
  input, output, session,
  question
) {
  
  ns <- getDefaultReactiveDomain()$ns
  
  # Functions that end in "_" are functions that are
  #   locally defined functions that wrap input functions with the same name
  #   and take minimal arguments

  button_type <- reactiveVal("submit", label = "button type")
  output$action_button_container <- renderUI({
    question_button_label(
      question,
      button_type(), 
      question_is_valid(question, input$answer)
    )
  })
  
  answer_container <- reactiveVal(NULL, label = "answer container")
  output$answer_container <- renderUI({
    answer_container()
  })
  
  message_container_info <- reactiveVal(NULL, label = "message container info")
  output$message_container <- renderUI({
    question_messages(question, req(message_container_info()))
  })
  

  init_question <- function() {
    if (question$random_answer_order) {
      question$answers <<- shuffle(question$answers)
    }
    
    answer_container(question_initialize_input(question))
    message_container_info(NULL)
    button_type("submit")
  }
  init_question()
  
  observeEvent(input$action_button, {
    # TODO-barret add logging of answer / correct / user / question
    # SEE question_submission_event

    if (button_type() == "try_again") {
      init_question()
      return()
    }
    
    # must be submit button
    is_correct_info <- question_is_correct(question, input$answer)

    # update the submit button label
    if (is_correct_info$is_correct) {
      button_type("correct")
    } else {
      # not correct
      if (isTRUE(question$allow_retry)) {
        # not correct, but may try again
        button_type("try_again")
      } else {
        # not correct and can not try again
        button_type("incorrect")
      }
    }

    # present all messages
    is_done <- (!isTRUE(question$allow_retry)) || is_correct_info$is_correct
    message_container_info(list(
      messages = is_correct_info$messages, 
      is_correct = is_correct_info$is_correct, 
      is_done = is_done
    ))
    if (is_done) {
      answer_container(question_completed_input(question, input$answer))
    }
    # TODO-barret disable the buttons and output
    # shinyjs::delay(1, {
    #   # namespace the selector to the answer module so someone can not disable other parts of the tutorial
    #   selector = paste0("#", ns("answer_container"), " ", question_disable_selector(question))
    #   # shinyjs::disable(selector = selector, asis = TRUE)
    #   # b/c there is no 'asis' param
    #   session$sendCustomMessage(type = "shinyjs-disable", message = list(selector = question_disable_selector(question)))
    # })
    cat("done with finalize!\n")
  })
    
}


# TODO-barret make reactive button layout
question_button_label <- function(question, label_type = "submit", is_valid = TRUE) {
  label_type <- match.arg(label_type, c("submit", "try_again", "correct", "incorrect"))
  button_label <- question$button_labels[[label_type]]
  is_valid <- isTRUE(is_valid)
  
  default_class <- "btn-primary"
  warning_class <- "btn-warning"
    
  if (label_type == "submit") {
    shiny::actionButton(question$ids$action_button, button_label, class = default_class)
    # TODO-barret use is_valid to show if disabled or not
  } else if (label_type == "try_again") {
    shiny::actionButton(question$ids$action_button, button_label, class = warning_class)
    # TODO-barret update css to work with btn-default
    # shinyjs::delay(1, {
    #   # make it show up orange
    #   shinyjs::removeClass("action_button", "btn-default")
    # })
  } else if (
    label_type == "correct" || 
    label_type == "incorrect"
  ) {
    NULL
  }
}

question_messages <- function(question, message_info) {
  messages <- message_info$messages
  is_correct <- message_info$is_correct
  is_done <- message_info$is_done

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
  quiz_text(paste0("Correct! ", sample(.praise, 1)))
}
random_encouragement <- function() {
  quiz_text(sample(.encourage, 1))
}




# 
# buttons <- shiny::radioButtons("123", "Barret", c("A", "B", "C"))
# 
# 
# 
# mutate_tags <- function() {
# 
# }
# 
# mutate_tags_recursive <- function() {
# 
# }
# 
