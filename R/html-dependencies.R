
#' Tutor HTML dependency
#' 
#' @details HTML dependency for core teachdown JS and CSS. This should be included as a 
#' dependency for custom tutorial formats that wish to ensure that that
#' teachdown.js and teachdown.css are loaded prior their own scripts and stylesheets.
#' 
#' @export
teachdown_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "teachdown",
    version = utils::packageVersion("teachdown"),
    src = html_dependency_src("lib", "teachdown"),
    script = "teachdown.js",
    stylesheet = "teachdown.css"
  )
}

teachdown_autocompletion_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "teachdown-autocompletion",
    version = utils::packageVersion("teachdown"),
    src = html_dependency_src("lib", "teachdown"),
    script = "teachdown-autocompletion.js"
  )
}

teachdown_diagnostics_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "teachdown-diagnostics",
    version = utils::packageVersion("teachdown"),
    src = html_dependency_src("lib", "teachdown"),
    script = "teachdown-diagnostics.js"
  )
}


html_dependency_src <- function(...) {
  if (nzchar(Sys.getenv("RMARKDOWN_SHINY_PRERENDERED_DEVMODE"))) {
    r_dir <- utils::getSrcDirectory(html_dependency_src, unique = TRUE)
    pkg_dir <- dirname(r_dir)
    file.path(pkg_dir, "inst", ...)
  }
  else {
    system.file(..., package = "teachdown")
  }
}


localforage_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "localforage",
    version = "1.4.3",
    src = system.file("lib/localforage", package = "teachdown"),
    script = "localforage.min.js"
  )
}

bootbox_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "bootbox",
    version = "4.4.0",
    src = system.file("lib/bootbox", package = "teachdown"),
    script = "bootbox.min.js"
  )
}

clipboardjs_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "clipboardjs",
    version = "1.5.15",
    src = system.file("lib/clipboardjs", package = "teachdown"),
    script = "clipboard.min.js"
  )
}


ace_html_dependency <- function() {
  htmltools::htmlDependency(
    name = "ace",
    version = ACE_VERSION,
    src = system.file("lib/ace", package = "teachdown"),
    script = "ace.js"
  )
}

