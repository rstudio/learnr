

tutor_html_dependency <- function() {
  
  # return package source directory when in dev mode
  tutor_src <- function() {
    if(nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
      r_dir <- getSrcDirectory(tutor_html_dependency, unique = TRUE)
      pkg_dir <- dirname(r_dir)
      file.path(pkg_dir, "inst", "lib", "tutor")
    }
    else {
      system.file("lib/tutor", package = "tutor")
    }
  }
  
  htmltools::htmlDependency(
    name = "tutor",
    version = utils::packageVersion("tutor"),
    src = tutor_src(),
    script = c(
      "tutor.js", 
      "exercise.js",
      "exercise-editor.js", 
      "exercise-evaluation.js", 
      "video.js"),
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

