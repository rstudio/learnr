
#' Run a tutorial
#' 
#' Run a tutorial which is contained within an R package.
#' 
#' @param name Tutorial name (subdirectory within \code{tutorials/} 
#'   directory of installed package).
#' @param package Name of package
#' @param shiny_args Additional arguments to forward to 
#'   \code{\link[shiny:runApp]{shiny::runApp}}. 
#' 
#' @details Note that when running a tutorial Rmd file with \code{run_tutorial}
#'   the tutorial Rmd should have already been rendered as part of the 
#'   development of the package (i.e. the correponding tutorial .html file for 
#'   the .Rmd file must exist).
#' 
#' @export
run_tutorial <- function(name, package, shiny_args = NULL) {
  
  # get path to tutorial
  tutorial_path <- system.file("tutorials", name, package = package)
 
  # validate that it's a direcotry
  if (!utils::file_test("-d", tutorial_path)) 
    stop("Tutorial ", name, " was not found in the ", package, " package.")
    
  # provide launch_browser if it's not specified in the shiny_args
  if (is.null(shiny_args))
    shiny_args <- list()
  if (is.null(shiny_args$launch.browser))
    shiny_args$launch.browser <- interactive()
  
  # run within tutorial wd and ensure we don't call rmarkdown::render
  withr::with_dir(tutorial_path, {
    rmarkdown::run(file = NULL, dir = tutorial_path, shiny_args = shiny_args)
  })
}
