

html_dependency_src <- function(...) {
  if(nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
    r_dir <- utils::getSrcDirectory(html_dependency_src, unique = TRUE)
    pkg_dir <- dirname(r_dir)
    file.path(pkg_dir, "inst", ...)
  }
  else {
    system.file(..., package = "tutor")
  }
}


tutor_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor",
    version = utils::packageVersion("tutor"),
    src = html_dependency_src("lib", "tutor"),
    script = c(
      "tutor.js", 
      "state.js",
      "exercise.js",
      "exercise-solution.js",
      "exercise-editor.js", 
      "exercise-evaluation.js", 
      "video.js"),
    stylesheet = "tutor.css"
  )
}

clipboardjs_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "clipboardjs",
    version = "1.5.15",
    src = system.file("lib/clipboardjs", package = "tutor"),
    script = "clipboard.min.js"
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

