

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
  
  # return package source directory when in live preview mode
  tutor_src <- function() {
    if(nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_LIVE_PREVIEW"))) {
      r_dir <- getSrcDirectory(tutor::initialize, unique = TRUE)
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

