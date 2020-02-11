
#' List Tutorial Dependencies
#'
#' List the \R packages required to run a particular tutorial.
#'
#' @param name The tutorial name.
#' @param package The \R package providing the tutorial.
#'
#' @export
tutorial_dependencies <- function(name, package) {

  # resolve tutorial path
  dir <- get_tutorial_path(name, package)

  # enumerate tutorial package dependencies
  deps <- renv::dependencies(dir, quiet = TRUE)
  sort(unique(deps$Package))

}
