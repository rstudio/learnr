
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
    name = "tutor-ace",
    version = "1.2.3",
    src = system.file("lib/ace", package = "tutor"),
    script = "ace.js"
  )
}