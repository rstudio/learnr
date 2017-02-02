
#' Tutor HTML dependency
#' 
#' @details HTML dependency for core tutor JS and CSS. This should be included as a 
#' dependency for custom tutorial formats that wish to ensure that that
#' tutor.js and tutor.css are loaded prior their own scripts and stylesheets.
#' 
#' @export
tutor_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor",
    version = utils::packageVersion("tutor"),
    src = html_dependency_src("lib", "tutor"),
    script = "tutor.js",
    stylesheet = "tutor.css"
  )
}

tutor_autocompletion_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor-autocompletion",
    version = utils::packageVersion("tutor"),
    src = html_dependency_src("lib", "tutor"),
    script = "tutor-autocompletion.js"
  )
}

tutor_diagnostics_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutor-diagnostics",
    version = utils::packageVersion("tutor"),
    src = html_dependency_src("lib", "tutor"),
    script = "tutor-diagnostics.js"
  )
}


html_dependency_src <- function(...) {
  if (nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
    r_dir <- utils::getSrcDirectory(html_dependency_src, unique = TRUE)
    pkg_dir <- dirname(r_dir)
    file.path(pkg_dir, "inst", ...)
  }
  else {
    system.file(..., package = "tutor")
  }
}


localforage_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "localforage",
    version = "1.4.3",
    src = system.file("lib/localforage", package = "tutor"),
    script = "localforage.min.js"
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
    version = ACE_VERSION,
    src = system.file("lib/ace", package = "tutor"),
    script = "ace.js"
  )
}

