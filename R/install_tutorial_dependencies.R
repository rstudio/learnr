install_tutorial_dependencies <- function(dir) {
  file_paths <- list.files(dir,
                           pattern = "[.]R$|[.]Rmd",
                           full.names = TRUE,
                           recursive = TRUE)
  deps <- lapply(file_paths, packrat:::fileDependencies)
  deps <- unique(unlist(deps))

  need_install <- deps[!deps %in% utils::installed.packages()]

  if(length(need_install) < 1) {
    return(invisible())
  }

  need_install_formatted <- paste("  -", need_install, collapse = "\n")
  question <- sprintf("Would you like to install the following packages?\n%s",
                      need_install_formatted)

  if(!interactive()) {
    stop("The following packages need to be installed:\n",
         need_install_formatted)
  }

  answer <- utils::menu(choices = c("yes", "no"),
                        title = question)

  if(answer == 2) stop("The tutorial is missing required packages and cannot be rendered.")

  utils::install.packages(need_install)
}
