
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
    version = utils::packageVersion("learnr"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial.js",
    stylesheet = "tutorial.css"
  )
}

tutorial_autocompletion_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-autocompletion",
    version = utils::packageVersion("learnr"),
    src = html_dependency_src("lib", "tutorial"),
    script = "tutorial-autocompletion.js"
  )
}

tutorial_diagnostics_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "tutorial-diagnostics",
    version = utils::packageVersion("learnr"),
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
    system.file(..., package = "learnr")
  }
}

idb_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "idb-keyvalue",
    version = "3.2.0",
    src = system.file("lib/idb-keyval", package = "learnr"),
    script = "idb-keyval-iife-compat.min.js",
    all_files = FALSE
  )
}

bootbox_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "bootbox",
    version = "4.4.0",
    src = system.file("lib/bootbox", package = "learnr"),
    script = "bootbox.min.js"
  )
}

clipboardjs_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "clipboardjs",
    version = "1.5.15",
    src = system.file("lib/clipboardjs", package = "learnr"),
    script = "clipboard.min.js"
  )
}


ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "ace",
    version = ACE_VERSION,
    src = system.file("lib/ace", package = "learnr"),
    script = "ace.js"
  )
}
