
#' @import rmarkdown
#' @importFrom htmltools htmlDependency attachDependencies HTML div tags
#' @importFrom knitr opts_chunk opts_knit opts_hooks knit_hooks knit_meta_add all_labels spin
#' @importFrom jsonlite base64_dec base64_enc
#' @importFrom htmlwidgets createWidget
#' @importFrom markdown markdownToHTML markdownExtensions
#' @importFrom evaluate evaluate
#' @importFrom withr with_envvar
#' @importFrom rprojroot find_root is_r_package
#' @importFrom shiny reactiveValues observeEvent req isolate invalidateLater isolate observe reactive
NULL

# install knitr hooks when package is attached to search path
.onAttach <- function(libname, pkgname) {
  install_knitr_hooks()
  initialize_tutorial()
}

# remove knitr hooks when package is detached from search path
.onDetach <- function(libpath) {
  remove_knitr_hooks()
}
