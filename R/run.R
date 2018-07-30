
#' Run a tutorial
#'
#' Run a tutorial which is contained within an R package.
#'
#' @param name Tutorial name (subdirectory within \code{tutorials/}
#'   directory of installed package).
#' @param package Name of package
#' @param shiny_args Additional arguments to forward to
#'   \code{\link[shiny:runApp]{shiny::runApp}}.
#' @param safe_session Boolean that determines if the exercises are evaluated
#'   in a new, safe R session.  Should only be necessary when locally deployed.
#'
#' @details Note that when running a tutorial Rmd file with \code{run_tutorial}
#'   the tutorial Rmd should have already been rendered as part of the
#'   development of the package (i.e. the correponding tutorial .html file for
#'   the .Rmd file must exist).
#'
#' @export
run_tutorial <- function(name, package, shiny_args = NULL, safe_session = FALSE) {

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
    withr::with_envvar(c(RMARKDOWN_RUN_PRERENDER = "0"), {
      render_fn <- if (isTRUE(safe_session)) run_safe else rmarkdown::run
      render_fn(file = NULL, dir = tutorial_path, shiny_args = shiny_args)
    })
  })
}


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
    system_command_interrupt = function() invisible(NULL)
  )
}

#' Render or Run documents in a new, safe R environment
#'
#' When rendering (or running) a document with R markdown, it inherits the current R Global environment.  This will produce unexpected behaviors, such as poisoning the R Global environment with existing variables.  By rendering the document in a new, safe R environment, a \emph{vanilla}, rendered document is produced.
#'
#' @param input,file Input file (R script, Rmd, or plain markdown).
#' @param ... extra arguements to be passed to \code{rmarkdown::\link[rmarkdown]{render}} or
#'   \code{rmarkdown::\link[rmarkdown]{run}}
#' @param show Logical, whether to show the standard output on the screen while the child process
#'   is running. Defaults to \code{TRUE}.
#' @export
#' @rdname render_safe
render_safe <- function(input, ..., show = TRUE) {
  callr_try_catch({
    callr::r(
      function(...) {
        rmarkdown::render(...)
      },
      list(input = input, ...),
      show = show,
      env = safe_env()
    )
  })
}
#' @export
#' @rdname render_safe
run_safe <- function(file, ..., show = TRUE) {
  callr_try_catch({
    callr::r(
      function(...) {
        rmarkdown::run(...)
      },
      list(file = file, ...),
      show = show,
      env = safe_env()
    )
  })
}
