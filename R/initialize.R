


#' Initialize Tutor R Markdown Extensions
#' 
#' One time initialization of R Markdonw extensions required by the 
#' \pkg{tutor} package. This function is typically called automatically 
#' as a result of using exercises or questions.
#' 
#' @export
initialize_tutor <- function() {
  
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
      'tutor:::register_http_handlers(session)',
      singleton = TRUE
    )
    
    # set initialized flag to ensure single initialization
    knitr::opts_knit$set(tutor.initialized = TRUE)
  }
}






