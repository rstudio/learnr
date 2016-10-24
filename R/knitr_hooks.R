
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
  
  # check for a tutor related chunk
  is_tutor_chunk <- function(options) {
    is_interactive_chunk(options) || is_exercise_chunk(options)
  }
  
  # set global tutor option which we can use as a basis for hooks
  # (this is so we don't collide with hooks set by the user or
  # by other packages or Rmd output formats)
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
      if (before) {
        paste0('<div class="tutor-', class, 
               '" data-label="', options$label, '">')
      }
      else {
        '</div>'
      }
    }
    
    # handle tutor chunks
    if (is_tutor_chunk(options)) {
      
      # ensure tutor js and css are included
      knitr::knit_meta_add(list(tutor_html_dependency()))
      
      # handle interactive chunks
      if (is_interactive_chunk(options)) {
        
        # output wrapper div
        tutor_wrapper_div("interactive")
        
        # TODO: generate shiny server code
      }
      # handle exercise chunks
      else if (is_exercise_chunk(options)) {
        
        # output wrapper div
        tutor_wrapper_div("exercise")
        
        # TODO: generate shiny server code
      } 
      
    }
  })
}

remove_knitr_hooks <- function() {
  knitr::opts_hooks$set(tutor = NULL)
  knitr::knit_hooks$set(tutor = NULL)
}

