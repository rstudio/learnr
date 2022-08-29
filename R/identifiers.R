
initialize_session_state <- function(session, metadata, location, request) {

  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
    else
      NULL
  }

  # function to initialize an identifier (read from http header or take default)
  initialize_identifier <- function(identifier, default) {

    # determine whether a custom header provides the value (fallback to default)
    header <- as_rook_header(getOption(sprintf("tutorial.http_header_%s", identifier)))
    if (!is.null(header) && exists(header, envir = request))
      value <- get(header, envir = request)
    else
      value <- default

    # write it into the request for reading later on
    write_request(session, sprintf("tutorial.%s", identifier), value)

    # return the value
    value
  }

  # determine if we're running inside a package, if so get pkg info
  pkg <- package_info()

  # save the location for later reading
  write_request(session, "tutorial.http_location", location)

  # initialize and return identifiers
  list(
    tutorial_id = initialize_identifier(
      "tutorial_id",
      default = default_tutorial_id(metadata$id, location, pkg)
    ),
    tutorial_version = initialize_identifier(
      "tutorial_version",
      default = default_tutorial_version(metadata$version, pkg)
    ),
    user_id = initialize_identifier("user_id", default = default_user_id()),
    language = initialize_identifier("language", default = default_language())
  )
}

package_info <- function() {
  # determine if we are running inside a package
  package_dir <- tryCatch(
    rprojroot::find_root(rprojroot::is_r_package, path = getwd()),
    error = function(e) NULL
  )

  if (!is.null(package_dir)) {
    package_desc <- file.path(package_dir, "DESCRIPTION")
    list(
      dir = package_dir,
      desc = package_desc,
      info = read.dcf(package_desc, all = TRUE)
    )
  }
}

default_tutorial_id <- function(id = NULL, location = NULL, pkg = package_info()) {
  # determine default tutorial id (metadata first then filesystem-based for
  # localhost and remote URL based for other configurations)
  if (!is.null(id)) return(id)

  if (!is_localhost(location)) {
    return(paste0(location$host, location$pathname))
  }

  if (is.null(pkg)) {
    return(getwd())
  }

  sprintf(
    "package:%s-%s",
    pkg$info$Package,
    sub(paste0("^", pkg$dir), "", getwd())
  )
}

default_tutorial_version <- function(version = NULL, pkg = package_info()) {
  # determine default version (if in a package use the package version)
  if (!is.null(version)) return(version)

  if (!is.null(pkg$dir)) {
    return(pkg$info$Version)
  }

  "1.0"
}

default_user_id <- function() {
  unname(Sys.info()["user"])
}

default_language <- function() {
  # knitr option > R global option > default
  knitr::opts_knit$get("tutorial.language") %||%
    getOption("tutorial.language", "en")
}

read_request <- function(session, name, default = NULL) {
  if (!is.null(name)) {
    if (is.environment(session$request) && exists(name, envir = session$request))
      get(name, envir = session$request)
    else
      default
  } else {
    default
  }
}

write_request <- function(session, name, value) {
  do.call("unlockBinding", list("request", session))
  session$request[[name]] <- value
  do.call("lockBinding", list("request", session))
}

