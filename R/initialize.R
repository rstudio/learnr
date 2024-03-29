


#' Initialize tutorial R Markdown extensions
#'
#' One time initialization of R Markdown extensions required by the
#' \pkg{learnr} package. This function is typically called automatically
#' as a result of using exercises or questions.
#'
#' @return If not previously run, initializes knitr hooks and provides the
#'   required [rmarkdown::shiny_prerendered_chunk()]s to initialize \pkg{learnr}.
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
      tutorial_html_dependency()
    ))

    # session initialization (forward tutorial metadata)
    rmarkdown::shiny_prerendered_chunk(
      'server',
      sprintf('learnr:::register_http_handlers(session, metadata = %s)',
              dput_to_string(rmarkdown::metadata$tutorial)),
      singleton = TRUE
    )

    # clear exercise/question and initialize user state reactive
    rmarkdown::shiny_prerendered_chunk(
      'server',
      'learnr:::prepare_tutorial_state(session)',
      singleton = TRUE
    )

    # record tutorial language in session object
    rmarkdown::shiny_prerendered_chunk(
      "server",
      "learnr:::i18n_observe_tutorial_language(input, session)"
    )

    # Register session stop handler
    rmarkdown::shiny_prerendered_chunk(
      'server',
      sprintf('session$onSessionEnded(function() {
        learnr:::event_trigger(session, "session_stop")
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
  # Must use a `"\n"` if `dput()`ing a function
  paste0(textConnectionValue(conn), collapse = "\n")
}
