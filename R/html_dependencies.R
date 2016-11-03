
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

slickquiz_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "slickquiz",
    version = "1.5.20",
    src = system.file("lib/slickquiz", package = "tutor"),
    script = "js/slickQuiz.js",
    stylesheet = "css/slickQuiz.css"
  )
}
