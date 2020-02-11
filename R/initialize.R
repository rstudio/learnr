


#' Initialize Tutorial R Markdown Extensions
#'
#' One time initialization of R Markdown extensions required by the
#' \pkg{tutor} package. This function is typically called automatically
#' as a result of using exercises or questions.
#'
#' @export
initialize_tutorial <- function() {

  # helper function for one time initialization
  if (isTRUE(getOption("knitr.in.progress")) &&
      !isTRUE(knitr::opts_knit$get("tutorial.initialized"))) {

    # html dependencies
    knitr::knit_meta_add(list(
      rmarkdown::html_dependency_jquery(),
      rmarkdown::html_dependency_font_awesome(),
      bootbox_html_dependency(),
      idb_html_dependency(),
      tutorial_html_dependency(),
      tutorial_autocompletion_html_dependency(),
      tutorial_diagnostics_html_dependency()
    ))

    # session initialization (forward tutorial metadata)
    rmarkdown::shiny_prerendered_chunk(
      'server',
      sprintf('learnr:::register_http_handlers(session, metadata = %s)',
              dput_to_string(rmarkdown::metadata$tutorial)),
      singleton = TRUE
    )

    # Register session stop handler
    rmarkdown::shiny_prerendered_chunk(
      'server',
      sprintf('session$onSessionEnded(function() {
        learnr:::session_stop_event(session)
      })'),
      singleton = TRUE
    )

    # set initialized flag to ensure single initialization
    knitr::opts_knit$set(tutorial.initialized = TRUE)
  }
}


dput_to_string <- function(x) {
  conn <- textConnection("dput_to_string", "w")
  on.exit({close(conn)})
  dput(x, file = conn)
  paste0(textConnectionValue(conn), collapse = "")
}
