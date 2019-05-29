
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
#' @return \code{available_tutorials} will return a \code{data.frame} containing "package", "name", and "title".
#' @rdname available_tutorials
#' @export
available_tutorials <- function(package = NULL) {

  info <-
    if (is.null(package)) {
      all_available_tutorials()
    } else {
      available_tutorials_for_package(package)
    }

  if (!is.null(info$error)) {
    stop.(info$error)
  }

  tutorials <- info$tutorials

  # return a data frame of tutorial pkg, name, and title
  return(tutorials)
}


#' @return will return a list of `error` and `tutorials` which is a \code{data.frame} containing "package", "name", and "title".
#' @noRd
available_tutorials_for_package <- function(package) {

  an_error <- function(...) {
    list(
      tutorials = NULL,
      error = paste0(...)
    )
  }

  if (!file.exists(
    system.file(package = package)
  )) {
    return(an_error(
      "No package found with name: \"", package, "\""
    ))
  }

  tutorials_dir <- system.file("tutorials", package = package)
  if (!file.exists(tutorials_dir)) {
    return(an_error(
      "No tutorials found for package: \"", package, "\""
    ))
  }

  tutorial_folders <- list.dirs(tutorials_dir, full.names = TRUE, recursive = FALSE)
  names(tutorial_folders) <- basename(tutorial_folders)
  rmd_info <- lapply(tutorial_folders, function(tut_dir) {
    dir_rmd_files <- dir(tut_dir, pattern = "\\.Rmd$", recursive = FALSE, full.names = TRUE)
    dir_rmd_files_length <- length(dir_rmd_files)
    if (dir_rmd_files_length == 0) {
      return(NULL)
    }
    if (dir_rmd_files_length > 1) {
      warning("Found multiple .Rmd files in \"", package, "\"'s \"", tut_dir, "\" folder.  Using: ", dir_rmd_files[1])
    }
    data.frame(
      package = package,
      name = basename(tut_dir),
      title = rmarkdown::yaml_front_matter(dir_rmd_files[1])$title %||% NA,
      stringsAsFactors = FALSE,
      row.names = FALSE
    )
  })

  has_no_rmd <- vapply(rmd_info, is.null, logical(1))
  if (all(has_no_rmd)) {
    return(an_error(
      "No tutorial .Rmd files found for package: \"", package, "\""
    ))
  }

  rmd_info <- rmd_info[!has_no_rmd]

  tutorials <- do.call(rbind, rmd_info)
  list(
    tutorials = structure(
      class = c("learnr_available_tutorials", class(tutorials)),
      tutorials
    ),
    error = NULL
  )
}

#' @return will return a list of `error` and `tutorials` which is a \code{data.frame} containing "package", "name", and "title".
#' @noRd
all_available_tutorials <- function() {
  ret <- list()
  all_pkgs <- base::library()$results[,"Package"]

  for (pkg in all_pkgs) {
    info <- available_tutorials_for_package(pkg)
    if (!is.null(info$tutorials)) {
      ret[[length(ret) + 1]] <- info$tutorials
    }
  }

  # do not check for size 0, as learnr contains tutorials.

  tutorials <- do.call(rbind, ret)

  list(
    tutorials = tutorials, # will maintain class
    error = NULL
  )
}


get_tutorial_path <- function(name, package) {

  tutorial_path <- system.file("tutorials", name, package = package)

  # validate that it's a direcotry
  if (!utils::file_test("-d", tutorial_path)) {
    tutorials <- available_tutorials(package)
    possible_tutorials <- tutorials$name
    msg <- paste0("Tutorial \"", name, "\" was not found in the \"", package, "\" package.")
    # if any tutorial names are _close_ tell the user
    adist_vals <- adist(possible_tutorials, name, ignore.case = TRUE)
    if (any(adist_vals <= 3)) {
      best_match <- possible_tutorials[which.min(adist_vals)]
      msg <- paste0(
        msg, "\n",
        "Did you mean \"", best_match, "\"?"
      )
    }
    stop.(msg, "\n", format(tutorials))
  }

  tutorial_path
}

#' @rdname available_tutorials
#' @export
format.learnr_available_tutorials <- function(x, ...) {
  tutorials <- x
  ret <- "Available tutorials:"

  for (pkg in unique(tutorials$package)) {
    tutorials_sub <- subset(tutorials, package == pkg)

    tutorial_names <- format(tutorials_sub$name)
    txts <- mapply(tutorial_names, tutorials_sub$title, SIMPLIFY = FALSE, FUN = function(name, title) {
      txt <- paste0("  - ", name)
      if (!is.na(title)) {
        txt <- paste0(txt, " : \"", title, "\"")
      }
      txt
    })

    ret <- paste0(
      ret, "\n",
      "* ", pkg, "\n",
      paste0(txts, collapse = "\n")
    )
  }

  ret
}
#' @rdname available_tutorials
#' @export
print.learnr_available_tutorials <- function(x, ...) {
  cat(format(x, ...), "\n")
}
