# TODO - make messages functions





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
                     type = c("auto", "single", "multiple", "text"),
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

  # # create question
  # question <- list(
  #   q = quiz_text(text),
  #   a = answers,
  #   correct = quiz_text(correct),
  #   incorrect = quiz_text(incorrect),
  # )
  type <- match.arg(type)

  total_correct <- sum(vapply(answers, function(ans) { ans$is_correct }, logical(1)))
  if (total_correct == 0) {
    stop("At least one correct answer must be supplied")
  }
  if (type == "auto") {
    if (total_correct > 1) {
      type <- "multiple"
    } else {
      type <- "single"
    }
  }

  return(list(
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
    type = type,
    random_answer_order = random_answer_order,
    allow_retry = allow_retry
  ))

  # if (type == "single")
  #   question$select_any <- TRUE
  # if (type == "multiple")
  #   question$force_checkbox <- TRUE

  # # save all state/options into "x"
  # x <- list()
  # x$question <- quiz_text(text)
  # x$answers <- answers
  # x$label <- knitr::opts_current$get('label')
  # x$skipStartButton <- TRUE # no start
  # x$perQuestionResponseAnswers <- TRUE
  # x$perQuestionResponseMessaging <- TRUE
  # x$preventUnanswered <- TRUE
  # x$displayQuestionCount <- FALSE
  # x$displayQuestionNumber <- FALSE
  # x$disableRanking <- TRUE
  # x$nextQuestionText <- ""
  # x$checkAnswerText <- "Submit Answer"
  # x$allowRetry <- allow_retry
  # x$randomSortAnswers = random_answer_order
  # x$json <- list(
  #   info = list(
  #     name = "",
  #     main = ""
  #   ),
  #   questions = list(question)
  # )

  # define dependencies
  dependencies <- list(
    rmarkdown::html_dependency_jquery(),
    rmarkdown::html_dependency_bootstrap(theme = "default"),
    bootbox_html_dependency(),
    localforage_html_dependency(),
    tutorial_html_dependency(),
    tutorial_autocompletion_html_dependency(),
    tutorial_diagnostics_html_dependency(),
    htmltools::htmlDependency(
      name = "slickquiz",
      version = "1.5.20",
      src = html_dependency_src("htmlwidgets", "lib", "slickquiz"),
      script = "js/slickQuiz.js",
      stylesheet = c("css/slickQuiz.css", "css/slickQuizTutorial.css")
    )
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'quiz',
    x = x,
    width = "100%",
    height = "auto",
    dependencies = dependencies,
    sizingPolicy = htmlwidgets::sizingPolicy(knitr.figure = FALSE,
                                             knitr.defaultWidth = "100%",
                                             knitr.defaultHeight = "auto",
                                             viewer.defaultWidth = "100%",
                                             viewer.defaultHeight = "auto"),
    package = 'learnr'
  )

}

#' @rdname quiz
#' @export
answer <- function(text, correct = FALSE, message = NULL) {
  if (!is.character(text)) {
    stop("Non-string `text` values are not allowed as an answer")
  }
  structure(class = "tutorial_quiz_answer", list(
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

  question$answers <- lapply(question$answers, function(ans) {
    ans$random_id <- random_answer_id()
    ans
  })

  # TODO make into a s3 method
  switch(question$type,
    single = radio_question_to_shiny(question),
    multiple = checkbox_question_to_shiny(question),
    text = text_question_to_shiny(question),
    # TODO-barret handle question type as s3 method
    carson = carson_question_to_shiny(question),
    stop("shiny app not implemented!")
  )
}


radio_question_to_shiny <- function(question) {

  init_answer_input <- function(answer_input_id, answers) {
    choice_names <- lapply(answers, function(ans) {
      ans$label
    })
    choice_values <- lapply(answers, function(ans) {
      ans$random_id
    })

    shiny::radioButtons(
      answer_input_id,
      label = question$question,
      choiceNames = choice_names,
      choiceValues = choice_values,
      selected = FALSE
    )
  }

  # # returns
  # list(
  #   is_correct = LOGICAL,
  #   message = CHARACTER
  # )
  answer_input_is_correct <- function(answer_input, answers) {
    for (ans in answers) {
      if (ans$random_id == answer_input) {
        return(list(
          is_correct = ans$is_correct,
          messages = ans$message,
          selected = list(
            ans
          )
        ))
      }
    }
    return(list(is_correct = FALSE, messages = NULL))
  }

  final_answer_input <- function(answer_input_id, answer_input, answers) {

    choice_values <- lapply(answers, function(ans) {
      ans$random_id
    })

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

    shiny::radioButtons(
      answer_input_id,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = answer_input
    )
  }

  assert_valid_answer_input <- function(answer_input) {
    if (is.null(answer_input)) {
      showNotification("Please select an answer before submitting", type = "error")
      req(answer_input)
    }
  }

  disable_css_selector <- function(answer_input_id) {
    paste0("#", answer_input_id, " .radio")
  }

  question_shiny_wrapper(
    question,
    init_answer_input,
    answer_input_is_correct,
    final_answer_input,
    assert_valid_answer_input,
    disable_css_selector
  )
}






checkbox_question_to_shiny <- function(question) {

  init_answer_input <- function(answer_input_id, answers) {
    choice_names <- lapply(answers, function(ans) {
      ans$label
    })
    choice_values <- lapply(answers, function(ans) {
      ans$random_id
    })

    shiny::checkboxGroupInput(
      answer_input_id,
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
  answer_input_is_correct <- function(answer_input, answers) {
    is_correct <- TRUE

    correct_messages <- c()
    incorrect_messages <- c()

    for (ans in answers) {
      ans_is_checked <- ans$random_id %in% answer_input
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

  final_answer_input <- function(answer_input_id, answer_input, answers) {

    choice_values <- lapply(answers, function(ans) {
      ans$random_id
    })

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
      answer_input_id,
      label = question$question,
      choiceValues = choice_values,
      choiceNames = choice_names_final,
      selected = answer_input
    )
  }

  assert_valid_answer_input <- function(answer_input) {
    if (is.null(answer_input)) {
      showNotification("Please select an answer before submitting", type = "error")
      req(answer_input)
    }
  }

  disable_css_selector <- function(answer_input_id) {
    paste0("#", answer_input_id, " .checkbox")
  }

  question_shiny_wrapper(
    question,
    init_answer_input,
    answer_input_is_correct,
    final_answer_input,
    assert_valid_answer_input,
    disable_css_selector
  )
}




text_question_to_shiny <- function(question) {

  init_answer_input <- function(answer_input_id, answers) {
    shiny::textInput(
      answer_input_id,
      label = question$question,
      placeholder = "Enter answer here..."
    )
  }

  # # returns
  # list(
  #   is_correct = LOGICAL,
  #   message = c(CHARACTER)
  # )
  answer_input_is_correct <- function(answer_input, answers) {

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

  final_answer_input <- function(answer_input_id, answer_input, answers) {
    shiny::textInput(
      answer_input_id,
      label = question$question,
      value = answer_input
    )
  }

  assert_valid_answer_input <- function(answer_input) {
    if (is.null(answer_input) || nchar(answer_input) == 0) {
      showNotification("Please select an answer before submitting", type = "error")
      req(answer_input)
    }
  }

  disable_css_selector <- function(answer_input_id) {
    paste0("#", answer_input_id)
  }

  question_shiny_wrapper(
    question,
    init_answer_input,
    answer_input_is_correct,
    final_answer_input,
    assert_valid_answer_input,
    disable_css_selector
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




question_shiny_wrapper <- function(
  question,
  init_answer_input,
  answer_input_is_correct,
  final_answer_input,
  assert_valid_answer_input,
  disable_css_selector
) {

  answer_input_id <- "answer_input"

  id <- random_question_id()
  ui <- question_module_ui(id, answer_input_id)
  # knitr::set_chunkattr(echo = FALSE)
  # rmarkdown::shiny_prerendered_chunk('server', sprintf('radio_question_to_shiny(\'IDIDID\', dput(question))'))
  
  callModule(
    question_module_server,
    id,
    question = question,
    init_answer_input = init_answer_input,
    answer_input_is_correct = answer_input_is_correct,
    final_answer_input = final_answer_input,
    assert_valid_answer_input = assert_valid_answer_input,
    disable_css_selector = disable_css_selector,
    answer_input_id = answer_input_id
  )
  ui
}

question_module_ui <- function(id, answer_input_id) {
  ns <- NS(id)
  tagList(
    shiny::includeCSS(system.file("htmlwidgets/lib/slickquiz/css/slickQuiz.css", package = "learnr")),
    shiny::includeCSS(system.file("htmlwidgets/lib/slickquiz/css/slickQuizTutorial.css", package = "learnr")),
    shinyjs::useShinyjs(),  # Set up shinyjs
    shiny::uiOutput(ns(answer_input_id)),
    shiny::uiOutput(ns("message")),
    shinyjs::disabled(
      shiny::actionButton(ns("action"), "loading...")
    )
  )
}

question_module_server <- function(
  input, output, session,
  question,
  init_answer_input,
  answer_input_is_correct,
  final_answer_input,
  assert_valid_answer_input,
  disable_css_selector,
  answer_input_id
) {

  # Functions that end in "_" are functions that are
  #   locally defined functions that wrap input functions with the same name
  #   and take minimal arguments

  answers <- question$answers

  button_label_type <- "submit"
  update_button_label_ <- function(label_type) {
    button_label_type <<- update_button_label(session, question, label_type)
  }

  init_question_ <- function() {
    if (question$random_answer_order) {
      answers <<- shuffle(answers)
    }
    output[[answer_input_id]] <- renderUI({init_answer_input(answer_input_id, answers)})

    output$message <- NULL
    update_button_label_("submit")
  }
  init_question_()

  # when a value changes, enable the action button
  observeEvent(input[[answer_input_id]], {
    shinyjs::enable("action")
  })

  observeEvent(input$action, {
    # TODO add logging of answer / correct / user / question
    # SEE question_submission_event

    if (button_label_type == "try_again") {
      init_question_()
      return()
    }

    assert_valid_answer_input(input[[answer_input_id]])

    is_correct_info <- answer_input_is_correct(input[[answer_input_id]], answers)

    # update the submit button label
    if (is_correct_info$is_correct) {
      update_button_label_("correct")
    } else {
      # not correct
      if (isTRUE(question$allow_retry)) {
        # not correct, but may try again
        update_button_label_("try_again")
      } else {
        # not correct and can not try again
        update_button_label_("incorrect")
      }
    }

    # present all messages
    is_done <- (!isTRUE(question$allow_retry)) || is_correct_info$is_correct
    update_messages(output, question, is_correct_info$messages, is_correct_info$is_correct, is_done)
    if (is_done) {
      output[[answer_input_id]] <- renderUI({final_answer_input(answer_input_id, input[[answer_input_id]], answers)})
    }
    shinyjs::delay(250, {
      shinyjs::disable(selector = disable_css_selector(answer_input_id))
    })
  })
}


update_button_label <- function(session, question, label_type = "submit") {
  valid_button_types <- list(submit = "submit", try_again = "try_again", correct = "correct", incorrect = "incorrect")
  label_type <- match.arg(label_type, unlist(unname(valid_button_types)))
  button_label <- question$button_labels[[label_type]]
  updateActionButton(session, "action", label = button_label)

  default_class <- "btn-primary"
  warning_class <- "btn-warning"

  if (label_type == valid_button_types$submit) {
    shinyjs::delay(1, {
      shinyjs::removeClass("action", warning_class)
      shinyjs::addClass("action", default_class)
      shinyjs::disable("action")
    })
  } else if (label_type == valid_button_types$try_again) {
    shinyjs::delay(1, {
      shinyjs::removeClass("action", default_class)
      shinyjs::addClass("action", warning_class)
      shinyjs::enable("action")
    })
  } else if (label_type == valid_button_types$correct) {
    shinyjs::delay(1, {
      shinyjs::removeClass("action", default_class)
      shinyjs::removeClass("action", warning_class)
      shinyjs::addClass("action", "btn-success")
      shinyjs::addClass("action", "hidden")
      shinyjs::disable("action")
    })
  } else if (label_type == valid_button_types$incorrect) {
    shinyjs::delay(1, {
      shinyjs::removeClass("action", default_class)
      shinyjs::removeClass("action", warning_class)
      shinyjs::addClass("action", "btn-danger")
      shinyjs::addClass("action", "hidden")
      shinyjs::disable("action")
    })
  }

  return(label_type)
}


# update message area below input / above submit button
update_messages <- function(output, question, messages, is_correct, is_done) {

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
    output$message <- NULL
  } else {
    output$message <- renderUI(tags$div(message_alert, post_alert))
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
