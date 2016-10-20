

# install knitr hooks when package is attached to search path
.onAttach <- function(libname, pkgname) {
  install_rmarkdown_hooks()
  install_knitr_hooks()
}

# remove knitr hooks when package is attached to search path
.onDetach <- function(libpath) {
  remove_knitr_hooks() 
}

install_rmarkdown_hooks <- function() {
  setHook("rmarkdown.onKnit", 
          function(input) install_knitr_hooks(), 
          action = "append")
  setHook("rmarkdown.onKnitCompleted",
          function(input) remove_knitr_hooks(),
          action = "append")
}

install_knitr_hooks <- function() {

  # check for runtime: shiny_prerendered being active
  is_shiny_prerendered_active <- function() {
    identical(knitr::opts_knit$get("rmarkdown.runtime"),"shiny_prerendered")
  }
  
  # check for an interactive chunk
  is_interactive_chunk <- function(options) {
    isTRUE(options[["interactive"]]) 
  }
  
  # check for an exercise related chunk
  is_exercise_chunk <- function(options) {
    if (grepl("^.*-exercise$", options$label))
      TRUE
    else if (grepl("^.*-(setup|check)$", options$label)) {
      exercise_label <- gsub("-(setup|check)$", "-exercise", options$label)
      label_query <- paste0("knitr::all_labels(label == '", exercise_label, "')")
      result <- eval(parse(text = label_query))
      length(result) == 1
    }
    else
      FALSE
  }

  # set global tutor option which we can use as a basis for hooks
  knitr::opts_chunk$set(tutor = TRUE)
  
  # option hook to turn off evaluation for exercise related chunks
  knitr::opts_hooks$set(tutor = function(options) {
  
    # bail if this isn't runtime: shiny_prerendered
    if (!is_shiny_prerendered_active())
      return(options)
    
    # if this is an exercise chunk then don't eval it
    if (is_exercise_chunk(options))
      options$eval = FALSE
    
    # return modified options
    options
  })


  # knit hook to amend output for interactive and exercise chunks
  knitr::knit_hooks$set(tutor = function(before, options, envir) {
    
    # bail if this isn't runtime: shiny_prerendered
    if (!is_shiny_prerendered_active())
      return(NULL)
    
    # produce a tutor wrapper div w/ the specified class
    tutor_wrapper_div <- function(class) {
      knitr::asis_output(
        if (before)
          paste0('<div class="tutor-', class, 
               '" data-label="', options$label, '">')
        else
          paste0('</div>')
      )
    }
    
    # handle interactive and exercise chunks
    if (is_interactive_chunk(options)) {
      
      # generate shiny server code
      
      # output wrapper div
      tutor_wrapper_div("interactive")
    }
    else if (is_exercise_chunk(options)) {
      
      # generate shiny server code
      
      
      # output wrapper div
      tutor_wrapper_div("exercise")
    }
  })
  
}

remove_knitr_hooks <- function() {
  knitr::opts_hooks$set(tutor = NULL)
  knitr::knit_hooks$set(tutor = NULL)
}

