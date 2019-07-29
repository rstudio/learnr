get_needed_pkgs <- function(dir) {

  packrat_dir_dependencies <- getFromNamespace("dirDependencies", "packrat")

  pkgs <- packrat_dir_dependencies(dir)

  pkgs[!pkgs %in% utils::installed.packages()]
}

format_needed_pkgs <- function(needed_pkgs) {
  paste("  -", needed_pkgs, collapse = "\n")
}

ask_pkgs_install <- function(needed_pkgs) {
  question <- sprintf("Would you like to install the following packages?\n%s",
                      format_needed_pkgs(needed_pkgs))

  utils::menu(choices = c("yes", "no"),
              title = question)
}

install_tutorial_dependencies <- function(dir) {
  needed_pkgs <- get_needed_pkgs(dir)

  if(length(needed_pkgs) < 1) {
    return(invisible())
  }

  if(!interactive()) {
    stop("The following packages need to be installed:\n",
         format_needed_pkgs(needed_pkgs))
  }

  answer <- ask_pkgs_install(needed_pkgs)

  if(answer == 2) {
    stop("The tutorial is missing required packages and cannot be rendered.")
  }

  utils::install.packages(needed_pkgs)
}
