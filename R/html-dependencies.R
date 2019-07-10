
#' Tutorial HTML dependency
#'
#' @details HTML dependency for core tutorial JS and CSS. This should be included as a
#' dependency for custom tutorial formats that wish to ensure that that
#' tutorial.js and tutorial.css are loaded prior their own scripts and stylesheets.
#'
#' @export
tutorial_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial",
    version = utils::packageVersion("learnrLara"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial.js",
    stylesheet = "tutorial.css"
  )
}

tutorial_autocompletion_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-autocompletion",
    version = utils::packageVersion("learnrLara"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial-autocompletion.js"
  )
}

tutorial_diagnostics_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-diagnostics",
    version = utils::packageVersion("learnrLara"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial-diagnostics.js"
  )
}


html_dependency_src <- function(...) {
  if (nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
    r_dir <- utils::getSrcDirectory(html_dependency_src, unique = TRUE)
    pkg_dir <- dirname(r_dir)
    file.path(pkg_dir, "inst", ...)
  }
  else {
    system.file(..., package = "learnrLara")
  }
}


localforage_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "localforage",
    version = "1.5",
    src = system.file("lib/localforage", package = "learnrLara"),
    script = "localforage.min.js"
  )
}

bootbox_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "bootbox",
    version = "4.4.0",
    src = system.file("lib/bootbox", package = "learnrLara"),
    script = "bootbox.min.js"
  )
}

clipboardjs_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "clipboardjs",
    version = "1.5.15",
    src = system.file("lib/clipboardjs", package = "learnrLara"),
    script = "clipboard.min.js"
  )
}


ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "ace",
    version = ACE_VERSION,
    src = system.file("lib/ace", package = "learnrLara"),
    script = "ace.js"
  )
}
