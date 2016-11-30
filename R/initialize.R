


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
  
    # is there a version provided via metadata?
    if (!is.null(rmarkdown::metadata$version)) {
      version <- rmarkdown::metadata$version
      if (is.numeric(version))
        version <- format(version, nsmall = 1)
      version <- sprintf('"%s"', version)
    }
    else
      version <- "NULL"
    
    # session initialization
    rmarkdown::shiny_prerendered_chunk(
      'server', 
      sprintf('tutor:::register_http_handlers(session, version = %s)', version),
      singleton = TRUE
    )
    
    # set initialized flag to ensure single initialization
    knitr::opts_knit$set(tutor.initialized = TRUE)
  }
}






