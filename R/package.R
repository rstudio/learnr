
#' @import htmltools
#' @import shiny
#' @import knitr
#' @import rmarkdown
#' @import uuid
#' @import markdown
NULL

# install knitr hooks when package is attached to search path
.onAttach <- function(libname, pkgname) {
  install_knitr_hooks()
}

# remove knitr hooks when package is detached from search path
.onDetach <- function(libpath) {
  remove_knitr_hooks() 
}



