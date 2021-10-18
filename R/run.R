#' Run a tutorial
#'
#' Run a tutorial which is contained within an R package.
#'
#' @param name Tutorial name (subdirectory within \code{tutorials/}
#'   directory of installed package), or the path to a local directory
#'   containing a learnr tutorial. If `package` is provided, `name` must be the
#'   tutorial name.
#' @param package Name of package. If `name` is a path to the local directory
#'   containing a learnr tutorials, then `package` should not be provided.
#' @param shiny_args Additional arguments to forward to
#'   \code{\link[shiny:runApp]{shiny::runApp}}.
#' @param clean When `TRUE`, the shiny prerendered HTML files are removed and
#'   the tutorial is re-rendered prior to starting the tutorial.
#' @param as_rstudio_job Runs the tutorial in the background as an RStudio job.
#'   This is the default behavior when `run_tutorial()` detects that RStudio
#'   is available and can run jobs. Set to `FALSE` to disable and to run the
#'   tutorial in the current R session.
#'
#'   When running as an RStudio job, `run_tutorial()` sets or overrides the
#'   `launch.browser` option for `shiny_args`. You can isntead use the
#'   `shiny.launch.browser` global option to in your current R session to set
#'   the default behavior when the tutorial is run. See [the shiny options
#'   documentation][shiny::getShinyOption()] for more information.
#' @param ... Unused. Included for future expansion and to ensure named
#'   arguments are used.
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
run_tutorial <- function(
  name = NULL,
  package = NULL,
  ...,
  shiny_args = NULL,
  clean = FALSE,
  as_rstudio_job = NULL
) {
  ellipsis::check_dots_empty()
  checkmate::assert_character(name, any.missing = FALSE, max.len = 1, null.ok = TRUE)
  checkmate::assert_character(package, any.missing = FALSE, max.len = 1, null.ok = TRUE)
  if (!is.null(name)) {
    name <- sub("/+$", "", name)
  }

  if (is.null(package)) {
    # is `name` a valid and existing directory for `rmarkdown::run()`?
    name <- run_validate_tutorial_path_is_dir(name)
    name_is_tutorial_path <- name$valid
    name <- name$value
  } else {
    name_is_tutorial_path <- FALSE
  }

  if (!name_is_tutorial_path && !is.null(name) && is.null(package)) {
    stop.("`package` must be provided if `name` is the name of a packaged tutorial. Otherwise, `name` must be a directory.")
  }

  # works for package = NULL and if package is provided
  if (!name_is_tutorial_path && is.null(name)) {
    tutorials <- available_tutorials(package = package)
    message(format(tutorials))
    return(invisible(tutorials))
  }

  # get path to tutorial directory
  tutorial_path <-
    if (name_is_tutorial_path) {
      normalizePath(name)
    } else {
      get_tutorial_path(name, package)
    }

  # check for necessary tutorial package dependencies
  install_tutorial_dependencies(tutorial_path)

  # provide launch_browser if it's not specified in the shiny_args
  if (is.null(shiny_args)) {
    shiny_args <- list()
  }
  if (is.null(shiny_args$launch.browser)) {
    is_interactive <- rlang::is_interactive() ||
      identical(Sys.getenv("LEARNR_INTERACTIVE", "0"), "1")

    shiny_args$launch.browser <- if (!is_interactive) {
      utils::browseURL
    } else {
      getOption("viewer", utils::browseURL)
    }
  }

  as_rstudio_job <-
    (isTRUE(as_rstudio_job) && can_run_rstudio_job(TRUE)) ||
    (is.null(as_rstudio_job) && can_run_rstudio_job())

  if (as_rstudio_job) {
    run_tutorial_as_job(name, package, shiny_args = shiny_args, clean = clean)
    return(invisible())
  }

  render_args <-
    tryCatch({
      local({
        # try to save a file to check for write permissions
        tmp_save_file <- file.path(tutorial_path, "__leanr_test_file")
        # make sure it's deleted
        on.exit({
          if (file.exists(tmp_save_file)) {
            unlink(tmp_save_file)
          }
        }, add = TRUE)
        # write to the test file
        suppressWarnings(cat("test", file = tmp_save_file))
        # if no errors have occurred, return an empty list of render_args
        list()
      })
    }, error = function(e) {
      # Could not write in the tutorial folder
      message("Rendering tutorial in a temp folder since `learnr` does not have write permissions in the tutorial folder: ", tutorial_path)

      # Set rmarkdown args to render in tmp dir
      # This will cause the tutorial to be re-rendered in each R session
      temp_output_dir <- file.path(tempdir(), "learnr", package, name)
      if (!dir.exists(temp_output_dir)) {
        dir.create(temp_output_dir, recursive = TRUE)
      }
      list(
        output_dir = temp_output_dir,
        intermediates_dir = temp_output_dir,
        knit_root_dir = temp_output_dir
      )
    })

  if (isTRUE(clean)) {
    run_clean_tutorial_prerendered(tutorial_path)
  }

  # ensure hooks are available for a tutorial and clean up after run_tutorial()
  if (!detect_installed_knitr_hooks()) {
    withr::defer(remove_knitr_hooks())
  }
  install_knitr_hooks()

  # run within tutorial wd
  withr::with_dir(tutorial_path, {
    if (!identical(Sys.getenv("SHINY_PORT", ""), "")) {
      # is currently running in a server, do not allow for prerender (rmarkdown::render)
      withr::local_envvar(c(RMARKDOWN_RUN_PRERENDER = "0"))
    }
    rmarkdown::run(file = NULL, dir = tutorial_path, shiny_args = shiny_args, render_args = render_args)
  })
}

run_validate_tutorial_path_is_dir <- function(path = NULL) {
  if (is.null(path)) return(list(valid = FALSE))

  # remove trailing slash, otherwise file.exists() returns FALSE on Windows
  # even if the directory exits. At this point we want to check that the input
  # does or doesn't exist. If it doesn't we don't need to do any more tests
  path <- sub("/+$", "", path)
  if (!file.exists(path)) {
    return(list(valid = FALSE, value = path))
  }

  if (!utils::file_test("-d", path)) {
    stop.("If `name` is a path to a tutorial, it must be the path to a directory containing a single tutorial.")
  }

  rmds <- list.files(path, pattern = "\\.rmd$", ignore.case = TRUE)
  if (length(rmds) == 0) {
    stop.("No R Markdown files found in the directory ", path)
  }

  if (length(rmds) > 1) {
    if (!"index.Rmd" %in% rmds) {
      stop.(
        "Multiple `.Rmd` files found in the directory, but none are named `index.Rmd`.",
        "\ndirectory: ", path,
        "\n     rmds: ", paste(rmds, collapse = ", ")
      )
    }
  }

  list(valid = TRUE, value = path)
}

run_find_tutorial_rmd <- function(path) {
  rmds <- list.files(path, pattern = "\\.rmd$", ignore.case = TRUE)
  if (length(rmds) == 0) {
    return(NULL)
  }

  if (length(rmds) > 1) {
    if (!"index.Rmd" %in% rmds) {
      return(NULL)
    }
    return("index.Rmd")
  }

  return(rmds)
}

run_clean_tutorial_prerendered <- function(path) {
  rmd <- run_find_tutorial_rmd(path)
  if (is.null(rmd)) {
    return(FALSE)
  }

  tryCatch({
    rmarkdown::shiny_prerendered_clean(file.path(path, rmd))
    TRUE
  }, error = function(err) {
    msg <- sprintf(
      'Could not clean shiny prerendered content. Error found while running `rmarkdown::shiny_prerendered_clean("%s")`:\n%s',
      file.path(path, rmd),
      conditionMessage(err)
    )
    message(msg)
    FALSE
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

can_run_rstudio_job <- function(stop_if_not = FALSE) {
  if (!rlang::is_interactive()) {
    return(FALSE)
  }

  has_needed_pkgs <- vapply(
    c("rstudioapi", "httpuv"), requireNamespace, logical(1), quietly = TRUE
  )

  if (any(!has_needed_pkgs)) {
    if (isTRUE(stop_if_not)) {
      pkgs <- c("rstudioapi", "httpuv")[!has_needed_pkgs]
      msg_err <- paste(
        ngettext(
          length(pkgs),
          sprintf("The %s package is", pkgs[1]),
          sprintf("The %s packages are", knitr::combine_words(pkgs))
        ),
        "required to run a tutorial as an RStudio job."
      )
      pkgs <- paste(pkgs, collapse = '", "')
      msg <- c(msg_err, "i" = sprintf('install.packages(c("%s"))', pkgs))
      rlang::abort(msg)
    }
    return(FALSE)
  }

  # rstudioapi::jobRunScript is internally called runScriptJob
  rstudioapi::hasFun("runScriptJob")
}

run_tutorial_as_job <- function(name, package = NULL, shiny_args = list(), clean = FALSE) {
  if (!can_run_rstudio_job() || !requireNamespace("httpuv", quietly = TRUE)) {
    stop("Cannot run tutorial as RStudio job")
  }

  if (is.null(shiny_args$port)) {
    shiny_args$port <- httpuv::randomPort()
  }

  shiny_args$launch.browser <- function(url) {
    message("\n+", strrep("-", getOption("width", 60) * 0.9), "+")
    tryCatch({
      job_call_parent <- function(expr) {
        expr <- rlang::parse_expr(expr)
        utils::getFromNamespace("callRemote", "rstudioapi")(expr, .GlobalEnv)
      }
      job_call_parent(
        sprintf('getOption("shiny.launch.browser", utils::browseURL)("%s")', url)
      )
      message("\u2713 Opened tutorial available at ", url)
    }, error = function(e) {
      message("\u2713 Open the tutorial in your browser: ", url)
    })
    message("! Stop or cancel this job to stop running the tutorial")
    message("+", strrep("-", getOption("width", 60) * 0.9), "+\n")
  }

  host <- if (is.null(shiny_args$host)) "127.0.0.1" else shiny_args$host
  url <- sprintf("http://%s:%s", sub("^https?://", "", host), shiny_args$port)

  script <- sprintf(
    'library(learnr)
    run_tutorial(%s, %s, shiny_args = %s, clean = %s)
    ',
    if (is.null(name)) "NULL" else paste0('"', name, '"'),
    if (is.null(package)) "NULL" else paste0('"', package, '"'),
    dput_to_string(shiny_args),
    if (isTRUE(clean)) "TRUE" else "FALSE"
  )

  tmpfile <- tempfile("run_tutorial", fileext = ".R")
  writeLines(script, tmpfile)

  job_name <- if (file.exists(name)) {
    rmd <- run_find_tutorial_rmd(name)
    if (!is.null(rmd)) {
      rmarkdown::yaml_front_matter(file.path(name, rmd))$title
    }
  } else {
    sprintf("%s {%s}", name, package)
  }

  rstudioapi::jobRunScript(
    path = tmpfile,
    workingDir = getwd(),
    name = job_name
  )
  invisible(url)
}
