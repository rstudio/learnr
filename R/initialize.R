


#' Initialize Tutor R Markdown Extensions
#' 
#' One time initialization of R Markdonw extensions required by the 
#' \pkg{tutor} package. This function is typically called automatically 
#' as a result of using exercises or questions.
#' 
#' @export
initialize <- function() {
  
  # helper function for one time initialization
  if (isTRUE(getOption("knitr.in.progress")) &&
      !isTRUE(knitr::opts_knit$get("tutor.initialized"))) {
    
    # html dependencies
    knitr::knit_meta_add(list(
      rmarkdown::html_dependency_jquery(),
      rmarkdown::html_dependency_font_awesome(),
      tutor_html_dependency()
    ))
    
    # session initialization
    rmarkdown::shiny_prerendered_chunk(
      'server', 
      'tutor:::initialize_shiny_session(session)',
      singleton = TRUE
    )
    
    # set initialized flag to ensure single initialization
    knitr::opts_knit$set(tutor.initialized = TRUE)
  }
}



# one-time initialization for Shiny session
initialize_shiny_session <- function(session) {
 
  # initialize session and user identifiers
  initialize_recording_identifiers(session)
  
  # register http handlers
  register_http_handlers(session)   
}





