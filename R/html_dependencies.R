

#' Initialize tutor within a document
#' 
#' @details 
#' Tutor is automatically initialiazed whenever you use an exercise
#' or a question so calling this function explicilty is typically not
#' required. You might need it if you were using e.g. only the video
#' embedding feature of tutor without exercises or questions.
#' 
#' @keywords internal
#' @export
initialize <- function() {
  knitr::knit_meta_add(list(
    rmarkdown::html_dependency_jquery(),
    tutor_html_dependency()
  ))
}

tutor_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor",
    version = utils::packageVersion("tutor"),
    src = system.file("lib/tutor", package = "tutor"),
    script = "tutor.js",
    stylesheet = "tutor.css"
  )
}

ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "ace",
    version = "1.2.3",
    src = system.file("lib/ace", package = "tutor"),
    script = "ace.js"
  )
}

