
tutor_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor",
    version = packageVersion("tutor"),
    src = system.file("www/tutor", package = "tutor"),
    script = "tutor.js",
    stylesheet = "tutor.css"
  )
}
