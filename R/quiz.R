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
  x <- list(message = "quiz")
  
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



