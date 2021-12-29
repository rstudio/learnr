#' Run a tutorial
#'
#' Run a tutorial provided by an installed R package.
#'
#' @param name Tutorial name (subdirectory within \code{tutorials/} directory of
#'   installed `package`). Alternatively, if `package` is not provided, `name`
#'   may be a path to a local tutorial R Markdown file or a local directory
#'   containing a learnr tutorial. If `package` is provided, `name` must be the
#'   tutorial name.
#' @param package Name of package. If `name` is a path to the local directory
#'   containing a learnr tutorial, then `package` should not be provided.
#' @param shiny_args Additional arguments to forward to
#'   \code{\link[shiny:runApp]{shiny::runApp}}.
#' @param clean When `TRUE`, the shiny prerendered HTML files are removed and
#'   the tutorial is re-rendered prior to starting the tutorial.
#' @param as_rstudio_job Runs the tutorial in the background as an RStudio job.
#'   This is the default behavior when `run_tutorial()` detects that RStudio is
#'   available and can run jobs. Set to `FALSE` to disable and to run the
#'   tutorial in the current R session.
#'
#'   When running as an RStudio job, `run_tutorial()` sets or overrides the
#'   `launch.browser` option for `shiny_args`. You can instead use the
#'   `shiny.launch.browser` global option in your current R session to set
#'   the default behavior when the tutorial is run. See [the shiny options
#'   documentation][shiny::getShinyOption()] for more information.
#' @param ... Unused. Included for future expansion and to ensure named
#'   arguments are used.
#'
#' @seealso \code{\link{safe}} and \code{\link{available_tutorials}}
#' @examples
#' # display all "learnr" tutorials
#' available_tutorials("learnr")
#'
#' # run basic example within learnr
#' \dontrun{
#' run_tutorial("hello", "learnr")
#' }
#'
#' @export
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

  if (is.null(name)) {
    tutorials <- available_tutorials(package = package)
    message(format(tutorials))
    return(invisible(tutorials))
  }

  # The tutorial object must have a boolean `valid` indicating if a valid
  # tutorial was found, and `dir` the normalized absolute path to the directory
  # containing the tutorial. Optionally, a `file` item will also be included,
  # indicating which specific tutorial will be run.
  tutorial <-
    if (is.null(package)) {
      run_validate_tutorial_path(name)
    } else {
      run_validate_tutorial_pkg(name, package)
    }

  if (!isTRUE(tutorial$valid)) {
    run_stop_invalid_name(name = name, package = package)
  }

  # check for necessary tutorial package dependencies
  install_tutorial_dependencies(tutorial$dir)

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
    (isTRUE(as_rstudio_job) && can_run_rstudio_job(stop_if_not = TRUE)) ||
    (is.null(as_rstudio_job) && can_run_rstudio_job())

  if (as_rstudio_job) {
    run_tutorial_as_job(name, package, shiny_args = shiny_args, clean = clean)
    return(invisible())
  }

  render_args <-
    tryCatch({
      local({
        # try to save a file to check for write permissions
        tmp_save_file <- file.path(tutorial$dir, "__learnr_test_file")
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
      message(
        "Rendering tutorial in a temp folder since `learnr` does not have write permissions in the tutorial folder: ",
        tutorial$dir
      )

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
    run_clean_tutorial_prerendered(tutorial$dir)
  }

  # ensure hooks are available for a tutorial and clean up after run_tutorial()
  if (!detect_installed_knitr_hooks()) {
    withr::defer(remove_knitr_hooks())
  }
  install_knitr_hooks()

  # run within tutorial wd
  withr::with_dir(tutorial$dir, {
    if (!identical(Sys.getenv("SHINY_PORT", ""), "")) {
      # is currently running in a server, do not allow for prerender (rmarkdown::render)
      withr::local_envvar(c(RMARKDOWN_RUN_PRERENDER = "0"))
    }
    rmarkdown::run(file = tutorial$file, dir = tutorial$dir, shiny_args = shiny_args, render_args = render_args)
  })
}

run_stop_invalid_name <- function(name = NULL, package = NULL, n_parent = 1) {
  msg <- if (is.null(package)) {
    sprintf(
      "Could not find a learnr tutorial at '%s'. When `package` is not provided, `name` must be the path to a tutorial `.Rmd` or a directory containing a learnr tutorial.",
      name
    )
  } else if (!is.null(name)) {
    sprintf("'%s' is not the name of a tutorial in the package '%s'.", name, package)
  } else {
    "When `package` is provided, `name` must be the name of a tutorial in the package. Otherwise `name` is the path to a tutorial or the path to a directory containing a tutorial."
  }
  if (!is.null(package)) {
    msg <- paste(msg, sprintf("Use `learnr::run_tutorial(package = \"%s\")` to list available tutorials in this package.", package))
  }
  stop(errorCondition(msg, call = sys.call(which = n_parent)))
}

run_validate_tutorial_path <- function(path = NULL) {
  tutorial_file <- run_validate_tutorial_file(path)
  if (isTRUE(tutorial_file$valid)) {
    return(tutorial_file)
  }

  tutorial_dir <- run_validate_tutorial_dir(path)
  if (isTRUE(tutorial_dir$valid)) {
    return(tutorial_dir)
  }

  list(valid = FALSE, dir = path)
}

run_validate_tutorial_dir <- function(path = NULL) {
  if (is.null(path)) return(list(valid = FALSE, dir = NULL))

  # remove trailing slash, otherwise file.exists() returns FALSE on Windows
  # even if the directory exits. At this point we want to check that the input
  # does or doesn't exist. If it doesn't we don't need to do any more tests
  path <- sub("/+$", "", path)
  if (!file.exists(path)) {
    return(list(valid = FALSE, dir = path))
  }

  run_find_tutorial_rmd(path, stop_if_not = TRUE)

  list(valid = TRUE, dir = normalizePath(path))
}

run_validate_tutorial_file <- function(path) {
  # A tutorial is valid if it's a scalar path to a single existing file that is a shiny rmd
  is_valid <- checkmate::test_character(path, len = 1, null.ok = FALSE, any.missing = FALSE) &&
    utils::file_test("-f", path) &&
    run_check_is_shiny_rmd(path)

  if (!isTRUE(is_valid)) {
    return(list(valid = FALSE, dir = path))
  }

  path <- normalizePath(path)

  list(valid = TRUE, file = basename(path), dir = dirname(path))
}

run_validate_tutorial_pkg <- function(name, package) {
  dir <- tryCatch(
    get_tutorial_path(name, package),
    error = identity
  )

  if (inherits(dir, "error")) {
    stop(
      errorCondition(
        conditionMessage(dir),
        call = sys.call(min(2, length(sys.calls())))
      )
    )
  }

  list(valid = TRUE, dir = dir)
}

run_check_is_shiny_rmd <- function(rmds) {
  vapply(rmds, FUN.VALUE = logical(1), function(x) {
    # this is one shortcut, we need a shiny prerendered or shinyrmd document
    runtime <- rmarkdown::yaml_front_matter(x)[["runtime"]]
    identical(runtime, "shinyrmd") || identical(runtime, "shiny_prerendered")
  })
}

run_find_tutorial_rmd <- function(path, stop_if_not = FALSE) {
  # TODO: replace when rstudio/rmarkdown#2236 is resolved
  # see https://github.com/rstudio/rmarkdown/blob/0af6b355/R/shiny.R#L69-L113
  # with a couple shortcuts because we know we need a learnr tutorial
  rmds <- list.files(path, pattern = "^[^_].*\\.[Rrq][Mm][Dd]$")
  names(rmds) <- rmds
  rmds <- file.path(path, rmds)

  if (length(rmds) == 0) {
    if (isTRUE(stop_if_not)) {
      stop.("No R Markdown files found in the directory ", path)
    }
    return(NULL)
  }

  is_shiny_rmd <- run_check_is_shiny_rmd(rmds)

  rmds <- basename(rmds[is_shiny_rmd])

  if (length(rmds) == 0) {
    if (isTRUE(stop_if_not)) {
      stop.("No `shiny_prerenderd` or `shinyrmd` R Markdown files found in the directory ", path)
    }
    return(NULL)
  }

  if (length(rmds) == 1) {
    return(rmds)
  }

  primary_rmds <- grepl("^(index|ui)[.]", tolower(rmds))
  if (sum(primary_rmds) == 1) {
    return(rmds[primary_rmds])
  }

  if (isTRUE(stop_if_not)) {
    stop.(
      "Unable to determine which of multiple R Markdown files is the primary app. ",
      "Name the primary app `index` with extension `.Rmd` or `.qmd`.",
      "\ndirectory: ", path,
      "\n     rmds: ", paste(rmds, collapse = ", ")
    )
  }

  NULL
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
#'
#' @keywords internal
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
      rlang::check_installed(c("rstudioapi", "httpuv"), "Required to run a tutorial as an RStudio job")
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

  call <- substitute(
    run_tutorial(
      name = name,
      package = package,
      shiny_args = shiny_args,
      clean = clean,
      as_rstudio_job = FALSE
    ),
    list(
      name = name,
      package = package,
      shiny_args = shiny_args,
      clean = clean
    )
  )

  script <- paste(c("library(learnr)", deparse(call)), collapse = "\n")

  tmpfile <- tempfile("run_tutorial", fileext = ".R")
  writeLines(script, tmpfile)

  # Set the job_name based on the tutorial title or name
  file <- name
  if (utils::file_test("-d", name)) {
    rmd <- run_find_tutorial_rmd(name)
    if (!is.null(rmd)) {
      file <- file.path(name, rmd)
    }
  }
  job_name <-
    if (file.exists(sub("/+$", "", file))) {
      paste("Tutorial:", rmarkdown::yaml_front_matter(file)$title)
    } else {
      sprintf("Tutorial: %s {%s}", name, package)
    }

  rstudioapi::jobRunScript(
    path = tmpfile,
    workingDir = getwd(),
    name = job_name
  )
  invisible(url)
}
