
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
      options$echo <- TRUE
      options$include <- TRUE
      options$highlight <- FALSE
      options$comment <- NA
    }
    
    # if this is an exercise support chunk then force echo, but don't 
    # eval or highlight it
    else if (is_exercise_support_chunk(options)) {
      options$echo <- TRUE
      options$include <- TRUE
      options$eval <- FALSE
      options$highlight <- FALSE
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
    exercise_wrapper_div <- function(suffix = NULL, extra_html = NULL) {
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
        c(extra_html, '</div>')
      }
    }
    
    # handle exercise chunks
    if (is_exercise_chunk(options)) {
      
      # one-time dependencies/server code
      extra_html <- NULL
      if (before) {
        # inject html dependencies
        knitr::knit_meta_add(list(
          ace_html_dependency(),
          tutor_html_dependency()
        ))
        
        # write server code
        exercise_server_chunk(options$label)
      } 
      else {
        # forward a subset of chunk options
        preserved_options <- list()
        preserved_options$fig.width <- options$fig.width
        preserved_options$fig.height <- options$fig.height
        preserved_options$fig.retina <- options$fig.retina
        preserved_options$fig.asp <- options$fig.asp
        preserved_options$fig.align <- options$fig.align
        preserved_options$fig.keep <- options$fig.keep
        preserved_options$fig.show <- options$fig.show
        preserved_options$fig.cap <- options$fig.cap
        preserved_options$out.width <- options$out.width
        preserved_options$out.height <- options$out.height
        preserved_options$out.extra <- options$out.extra
        preserved_options$warning <- options$warning
        preserved_options$error <- options$error
        preserved_options$message <- options$message
        
        # script tag with knit options for this chunk
        extra_html <- c('<script type="application/json" data-opts-chunk="1">',
                        jsonlite::toJSON(preserved_options, auto_unbox = TRUE),
                        '</script>')
      }
      
      # wrapper div (called for before and after)
      exercise_wrapper_div(extra_html = extra_html)
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

exercise_server_chunk <- function(label) {
  rmarkdown::shiny_prerendered_chunk('server', sprintf(
'output$`tutor-exercise-%s-output` <- renderUI({
  eventReactive(input$`tutor-exercise-%s-button`, {
    tutor:::run_exercise(input$`tutor-exercise-%s-code-editor`)
  })()
})', label, label, label))
}

