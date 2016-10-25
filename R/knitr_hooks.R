
install_knitr_hooks <- function() {
  
  # set global tutor option which we can use as a basis for hooks
  # (this is so we don't collide with hooks set by the user or
  # by other packages or Rmd output formats)
  knitr::opts_chunk$set(tutor = TRUE)
  
  # helper to check for runtime: shiny_prerendered being active
  is_shiny_prerendered_active <- function() {
    identical(knitr::opts_knit$get("rmarkdown.runtime"),"shiny_prerendered")
  }
  
  # helper to check for an exercise chunk
  is_exercise_chunk <- function(options) {
    isTRUE(options[["exercise"]]) 
  }
  
  # helper to check for an exercise support chunk
  is_exercise_support_chunk <- function(options) {
    support_regex <- "-(setup|solution|check)$"
    if (grepl(support_regex, options$label)) {
      exercise_label <- sub(support_regex, "", options$label)
      all_exercise_labels <- knitr::all_labels(exercise == TRUE)
      exercise_label %in% all_exercise_labels
    }
    else {
      FALSE
    }
  }
 
  # hook to turn off evaluation/highlighting for exercise related chunks
  knitr::opts_hooks$set(tutor = function(options) {
    
    # bail if this isn't runtime: shiny_prerendered
    if (!is_shiny_prerendered_active())
      return(options)
    
    # if this is an exercise chunk then force echo and don't highlight it
    if (is_exercise_chunk(options)) {
      options$echo = TRUE
      options$include = TRUE
      options$highlight = FALSE
    }
    
    # if this is an exercise support chunk then force echo, but don't 
    # eval or highlight it
    else if (is_exercise_support_chunk(options)) {
      options$echo = TRUE
      options$include = TRUE
      options$eval = FALSE
      options$highlight = FALSE
    }
    
    # return modified options
    options
  })
  
  # hook to amend output for exercise related chunks
  knitr::knit_hooks$set(tutor = function(before, options, envir) {
    
    # bail if this isn't runtime: shiny_prerendered
    if (!is_shiny_prerendered_active())
      return(NULL)
    
    # helper to produce an exercise wrapper div w/ the specified class
    exercise_wrapper_div <- function(suffix = NULL) {
      # before exercise
      if (before) {
        if (!is.null(suffix))
          suffix <- paste0("-", suffix)
        class <- paste0("exercise", suffix)
        paste0('<div class="tutor-', class, 
               '" data-label="', options$label, '">')
      }
      # after exercise
      else {
        c(sprintf('<div id="tutor-%s-output" class="shiny-html-output"></div>',
                  options$label),
          '</div>')
      }
    }
    
    # handle exercise chunks
    if (is_exercise_chunk(options)) {
      
      # inject html dependencies
      knitr::knit_meta_add(list(
        ace_html_dependency(),
        tutor_html_dependency()
      ))
      
      #
      # TODO: generate shiny server code
      #
      
      # output wrapper div
      exercise_wrapper_div()
    }
    
    # handle exercise support chunks (setup, solution, and check)
    else if (is_exercise_support_chunk(options)) {
      
      # output wrapper div
      exercise_wrapper_div(suffix = "support")
    } 
      
    
  })
}

remove_knitr_hooks <- function() {
  knitr::opts_hooks$set(tutor = NULL)
  knitr::knit_hooks$set(tutor = NULL)
}

