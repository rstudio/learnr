#' Tutorial quiz question
#'
#' Add an interative multiple choice quiz question to a tutorial.
#'
#' @param text Question or option text
#' @param type Type of quiz question. Typically this can be automatically determined
#'   based on the provided answers Pass \code{"single"} to indicate that even though
#'   multiple correct answers are specified that inputs which include only one correct
#'   answer are still correct. Pass \code{"multiple"} to force the use of checkboxes
#'   (as opposed to radio buttons) even though only once correct answer was provided.
#' @param correct For \code{question}, text to print for a correct answer (defaults 
#'   to "Correct!"). For \code{answer}, a boolean indicating whether this answer is
#'   correct.
#' @param incorrect Text to print for an incorrect answer (defaults to "Incorrect.")
#' @param ... One or more answers 
#' @param random_answer_order Display answers in a random order.
#' 
#' @examples 
#' \dontrun{
#' question("What number is the letter A in the alphabet?",
#'   answer("8"),
#'   answer("14"),
#'   answer("1", correct = TRUE),
#'   answer("23")
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
#' @name question
#' @export
question <- function(text, 
                     ..., 
                     type = c("auto", "single", "multiple"),
                     correct = "Correct!", 
                     incorrect = "Incorrect.",
                     random_answer_order = FALSE) {
  
  # capture/validate answers
  answers <- list(...)
  lapply(answers, function(answer) {
    if (!inherits(answer, "tutor_quiz_answer"))
      stop("Object which is not an answer passed to question function")
  })
  
  # create question
  question <- list(
    q = text,
    a = answers,
    correct = correct,
    incorrect = incorrect
  )
  type <- match.arg(type)
  if (type == "single")
    question$select_any <- TRUE
  if (type == "multiple")
    question$force_checkbox <- TRUE
  
  # save all state/options into "x"
  x <- list()
  x$skipStartButton <- TRUE
  x$perQuestionResponseAnswers <- TRUE
  x$perQuestionResponseMessaging <- TRUE
  x$preventUnanswered <- TRUE
  x$displayQuestionCount <- FALSE
  x$displayQuestionNumber <- FALSE
  x$disableRanking <- TRUE
  x$nextQuestionText <- ""
  x$checkAnswerText <- "Submit Answer"
  x$randomSortAnswers = random_answer_order
  x$json <- list(
    info = list(
      name = "",
      main = ""
    ),
    questions = list(question)
  )
 
  # define dependencies
  dependencies <- list(
    rmarkdown::html_dependency_jquery(),
    rmarkdown::html_dependency_bootstrap(theme = "default"),
    htmltools::htmlDependency(
      name = "slickquiz",
      version = "1.5.20",
      src = system.file("htmlwidgets/lib/slickquiz", package = "tutor"),
      script = "js/slickQuiz.js",
      stylesheet = c("css/slickQuiz.css", "css/tutor.css")
    )
  )
  
  # create widget
  htmlwidgets::createWidget(
    name = 'quiz',
    x = x,
    width = NULL,
    height = NULL,
    dependencies = dependencies,
    sizingPolicy = htmlwidgets::sizingPolicy(knitr.figure = FALSE, 
                                             knitr.defaultWidth = "100%", 
                                             knitr.defaultHeight = "auto"),
    package = 'tutor'
  )
}

#' @rdname question
#' @export
answer <- function(text, correct = FALSE) {
  structure(class = "tutor_quiz_answer", list(
    option = text,
    correct = correct
  ))
}


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


