
initialize_identifiers <- function(session, version, request) {
  
  # helper to read rook headers
  as_rook_header <- function(name) {
    if (!is.null(name))
      paste0("HTTP_", toupper(gsub("-", "_", name, fixed = TRUE)))
    else
      NULL
  }
  
  # function to initialize an identifier (read from http header or take default)
  initialize_identifer <- function(identifier, default) {
    
    # determine whether a custom header provides the value (fallback to default)
    header <- as_rook_header(getOption(sprintf("tutor.http_header_%s", identifier)))
    if (!is.null(header) && exists(header, envir = request))
      value <- get(header, envir = request)
    else
      value <- default
    
    # write it into the request for reading later on
    write_request(session, sprintf("tutor.%s", identifier), value)
    
    # return the value
    value
  }
  
  # determine if we are running inside a package 
  cwd <- getwd()
  package_dir <- tryCatch(rprojroot::find_root(rprojroot::is_r_package, 
                                               path = cwd),
                          error = function(e) NULL)
  if (!is.null(package_dir)) {
    package_desc <- file.path(package_dir, "DESCRIPTION")
    package_info <- read.dcf(package_desc, all = TRUE)
  }
 
  # determine default tutorial id 
  if (!is.null(package_dir)) {
    default_tutorial_id <- sprintf("package:%s-%s", 
                                   package_info$Package,
                                   sub(paste0("^", package_dir), "", cwd))
  }
  else {
    default_tutorial_id <- cwd  
  }
  
  # determine default version (if in a package use the package version)
  default_tutorial_version <- version
  if (is.null(default_tutorial_version)) {
    if (!is.null(package_dir))
      default_tutorial_version <- package_info$Version
    else
      default_tutorial_version <- "1.0"
  }
 
  # initialize and return identifiers
  list(
    # tutorial_id
    tutorial_id = initialize_identifer("tutorial_id", 
                                       default = default_tutorial_id),
    # tutorial_version
    tutorial_version = initialize_identifer("tutorial_version", 
                                            default = default_tutorial_version),
    # user id
    user_id = initialize_identifer("user_id", 
                                   default = unname(Sys.info()["user"]))
  )
}

read_request <- function(session, name, default = NULL) {
  if (!is.null(name)) {
    if (exists(name, envir = session$request))
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



