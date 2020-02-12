get_needed_pkgs <- function(dir) {

  pkgs <- tutorial_dir_package_dependencies(dir)

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

  if(length(needed_pkgs) == 0) {
    return(invisible(NULL))
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




#' List Tutorial Dependencies
#'
#' List the \R packages required to run a particular tutorial.
#'
#' @param name The tutorial name. If \code{name} is \code{NULL}, then all
#'   tutorials within \code{package} will be searched.
#' @param package The \R package providing the tutorial. If \code{package} is
#'   \code{NULL}, then all tutorials will be searched.
#'
#' @export
#' @return A character vector of package names that are required for execution.
#' @examples
#' tutorial_package_dependencies(package = "learnr")
tutorial_package_dependencies <- function(name = NULL, package = NULL) {
  if (identical(name, NULL)) {
    info <- available_tutorials(package = package)
    return(
      sort(unique(unlist(info$package_dependencies)))
    )
  }

  tutorial_dir_package_dependencies(
    get_tutorial_path(name = name, package = package)
  )
}

tutorial_dir_package_dependencies <- function(dir) {
  # enumerate tutorial package dependencies
  deps <- renv::dependencies(dir, quiet = TRUE)

  # R <= 3.4 can not sort(NULL)
  # if no deps are found, renv::dependencies returns NULL
  if (is.null(deps)) {
    return(NULL)
  }

  sort(unique(deps$Package))
}
