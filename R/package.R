
#' @importFrom htmltools htmlDependency attachDependencies HTML div tags
#' @importFrom knitr opts_chunk opts_knit opts_hooks knit_hooks knit_meta_add all_labels spin
#' @importFrom rmarkdown shiny_prerendered_chunk knitr_options_html output_format html_fragment render shiny_prerendered_server_start_code
#' @importFrom jsonlite serializeJSON unserializeJSON
#' @importFrom htmlwidgets createWidget
#' @importFrom markdown markdownToHTML markdownExtensions
#' @importFrom evaluate evaluate
NULL

# install knitr hooks when package is attached to search path
.onAttach <- function(libname, pkgname) {
  install_knitr_hooks()
}

# remove knitr hooks when package is detached from search path
.onDetach <- function(libpath) {
  remove_knitr_hooks() 
}



