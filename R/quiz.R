#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @param ... One or more quiz questions
#' @param caption Text caption
#'
#' @name quiz
#' @export
question <- function(text, 
                     ..., 
                     correct = "Correct!", 
                     incorrect = "Incorrect.") {

  # capture/validate answers
  answers <- list(...)
  
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
  x$json <- list(
    info = list(
      name = "Question",
      main = ""
    ),
    questions = list(list(
      q = text,
      a = answers,
      correct = correct,
      incorrect = incorrect
    ))
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
      stylesheet = "css/slickQuiz.css"
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

#' @rdname quiz
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
<div class="panel panel-info">
<div class="panel-heading quizName"></div>
<div class="panel-body quizArea">
</div>
</div>
</div>
', id, style, class))
}


