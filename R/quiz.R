#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @param ... One or more quiz questions
#' @param caption Text caption
#'
#' @export
quiz <- function(..., caption = NULL) {

  # capture questions
  questions <- list(...)
  
  # save all state/options into "x"
  x <- list()
  x$quiz <- list(
    info = list(
      name = "Test your knowledge!",
      main = "The Quiz Description Text"
    ),
    questions = list(
      list(
        q = "What number is the letter A in the English alphabet?",
        a = list(
          list(option = "8", correct = FALSE),
          list(option = "14", correct = FALSE),
          list(option = "1", correct = TRUE),
          list(option = "23", correct = FALSE)
        ),
        correct = "Great job!",
        incorrect = "You got it wrong!"
      )
    )
  )
 
  
  # define dependencies
  dependencies <- list(
    rmarkdown::html_dependency_jquery(),
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
question <- function(caption) {
  structure(class = "quiz_question", list(
    caption = caption
  ))
}


quiz_html <- function(id, style, class, ...) {
  htmltools::HTML(sprintf('
<div id="%s" style="%s", class = "%s">
<div class="quizName"></div>
<div class="quizArea">
<div class="quizHeader">
<a class="startQuiz" href="">Get Started!</a>
</div>
</div>
<div class="quizResults">
<div class="quizScore">You Scored: <span></span></div>
<div class="quizLevel"><strong>Ranking:</strong> <span></span></div>
<div class="quizResultsCopy"></div>
</div>
</div>
', id, style, class))
}


