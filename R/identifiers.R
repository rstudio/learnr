
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
  
  # determine default tutorial id 
  default_tutorial_id <- getwd()
  
  
  # determine default version
  default_tutorial_version <- version
  if (is.null(default_tutorial_version)) {

    # if we are running inside a package use the package version
    description_file <- tryCatch(rprojroot::find_package_root_file("DESCRIPTION"),
                            error = function(e) NULL)
    if (!is.null(description_file))
      default_tutorial_version <- unname(read.dcf(description_file, 
                                                  fields = ("Version"))[1,1])
  
    # fallback to version 1
    if (is.null(default_tutorial_version))
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



