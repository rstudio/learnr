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
#'   development of the package (i.e. the corresponding tutorial .html file for
#'   the .Rmd file must exist).
#'
#' @seealso \code{\link{safe}} and \code{\link{available_tutorials}}
#' @importFrom utils adist
#' @export
#' @examples
#' # display all "learnr" tutorials
#' available_tutorials("learnr")
#'
#' # run basic example within learnr
#' \dontrun{run_tutorial("hello", "learnr")}
run_tutorial <- function(name = NULL, package = NULL, shiny_args = NULL) {

  if (is.null(package) && !is.null(name)) {
    stop.("`package` must be provided if `name` is provided.")
  }

  # works for package = NULL and if package is provided
  tutorials <- available_tutorials(package = package)
  if (is.null(name)) {
    message(format(tutorials))
    return(invisible(tutorials))
  }

  # get path to tutorial
  tutorial_path <- get_tutorial_path(name, package)

  # check for necessary tutorial package dependencies
  install_tutorial_dependencies(tutorial_path)

  # provide launch_browser if it's not specified in the shiny_args
  if (is.null(shiny_args))
    shiny_args <- list()
  if (is.null(shiny_args$launch.browser)) {
    shiny_args$launch.browser <- (
      interactive() ||
        identical(Sys.getenv("LEARNR_INTERACTIVE", "0"), "1")
    )
  }

  # run within tutorial wd
  withr::with_dir(tutorial_path, {
    if (!identical(Sys.getenv("SHINY_PORT", ""), "")) {
      # is currently running in a server, do not allow for prerender (rmarkdown::render)
      withr::local_envvar(c(RMARKDOWN_RUN_PRERENDER = "0"))
    }
    rmarkdown::run(file = NULL, dir = tutorial_path, shiny_args = shiny_args)
  })
}


#' Safe R CMD environment
#'
#' By default, \code{callr::\link[callr]{rcmd_safe_env}} suppresses the ability
#' to open a browser window.  This is the default execution environment within
#' \code{callr::\link[callr]{r}}.  However, opening a browser is expected
#' behavior within the learnr package and should not be suppressed.
#' @export
safe_env <- function() {
  envs <- callr::rcmd_safe_env()
  envs[!(names(envs) %in% c("R_BROWSER"))]
}


callr_try_catch <- function(...) {
  tryCatch(
    ...,
    # TODO when processx 3.2.0 is released, _downgrade_ to "interrupt" call instead of "system_command_interrupt".
    # https://github.com/r-lib/processx/issues/148

    # if a user sends an interrupt, return silently
    system_command_interrupt = function(...) invisible(NULL)
  )
}


#' Execute R code in a safe R environment
#'
#' When rendering (or running) a document with R markdown, it inherits the
#' current R Global environment.  This will produce unexpected behaviors,
#' such as poisoning the R Global environment with existing variables.  By
#' rendering the document in a new, safe R environment, a \emph{vanilla},
#' rendered document is produced.
#'
#' The environment variable \code{LEARNR_INTERACTIVE} will be set to \code{"1"}
#' or \code{"0"} depending on if the calling session is interactive or not.
#'
#' Using \code{safe} should only be necessary when locally deployed.
#'
#' @param expr expression that contains all the necessary library calls to
#'   execute.  Expressions within callr do not inherit the existing,
#'   loaded libraries.
#' @param ... parameters passed to \code{callr::\link[callr]{r}}
#' @param show Logical that determines if output should be displayed
#' @param env Environment to evaluate the document in
#' @export
#' @examples
#' \dontrun{
#' # Direct usage
#' safe(run_tutorial("hello", package = "learnr"))
#'
#' # Programmatic usage
#' library(rlang)
#'
#' expr <- quote(run_tutorial("hello", package = "learnr"))
#' safe(!!expr)
#'
#' tutorial <- "hello"
#' safe(run_tutorial(!!tutorial, package = "learnr"))
#' }
safe <- function(expr, ..., show = TRUE, env = safe_env()) {
  # do not make a quosure as the attached env is not passed.
  # should be evaluated in a clean global context
  expr <- rlang::enexpr(expr)

  # "0" or "1"
  learnr_interactive = as.character(as.numeric(isTRUE(interactive())))

  callr_try_catch({
    withr::with_envvar(c(LEARNR_INTERACTIVE = learnr_interactive), {
      callr::r(
        function(.exp) {
          library("learnr", character.only = TRUE, quietly = TRUE)
          base::eval(.exp)
        },
        list(
          .exp = expr
        ),
        ...,
        show = show,
        env = env
      )
    })
  })
}
