
tutor_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor",
    version = packageVersion("tutor"),
    src = system.file("www/tutor", package = "tutor"),
    script = "tutor.js",
    stylesheet = "tutor.css"
  )
}

ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor-ace",
    version = "1.2.3",
    src = system.file("www/ace-1.2.3", package = "tutor"),
    script = "ace.js"
  )
}