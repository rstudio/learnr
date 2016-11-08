
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
  
  # helper to find chunks that name a chunk as their setup chunk
  exercise_chunks_for_setup_chunk <- function(label) {
    label_query <- paste0("knitr::all_labels(exercise.setup == '", label, "')")
    eval(parse(text = label_query))
  }
  
  # helper to check for an exercise support chunk
  is_exercise_support_chunk <- function(options, type = c("setup", "solution", "check")) {
    support_regex <- paste0("-(", paste(type, collapse = "|"), ")$")
    if (grepl(support_regex, options$label)) {
      exercise_label <- sub(support_regex, "", options$label)
      label_query <- "knitr::all_labels(exercise == TRUE)"
      all_exercise_labels <- eval(parse(text = label_query))
      exercise_label %in% all_exercise_labels
    }
    else if ("setup" %in% type) {
      # look for another chunk which names this as it's setup chunk
      length(exercise_chunks_for_setup_chunk(options$label)) > 0
    }
    else {
      FALSE
    }
  }
 
  # hook to turn off evaluation/highlighting for exercise related chunks
  knitr::opts_hooks$set(tutor = function(options) {
    
    # check for chunk type
    exercise_chunk <- is_exercise_chunk(options)
    exercise_support_chunk <- is_exercise_support_chunk(options)
    exercise_setup_chunk <- is_exercise_support_chunk(options, type = "setup")
    
    # validate that we have runtime: shiny_prerendered
    if ((exercise_chunk || exercise_support_chunk) && !is_shiny_prerendered_active()) {
      stop("Tutorial exercises require the use of 'runtime: shiny_prerendered'",
           call. = FALSE)
    }
    
    # if this is an exercise chunk then set various options
    if (exercise_chunk) {
      options$echo <- TRUE
      options$include <- TRUE
      options$highlight <- FALSE
      options$comment <- NA
      if (!is.null(options$exercise.eval))
        options$eval <- options$exercise.eval
      else
        options$eval <- FALSE
    }
    
    # if this is an exercise support chunk then force echo, but don't 
    # eval or highlight it
    if (exercise_support_chunk) {
      options$echo <- TRUE
      options$include <- TRUE
      options$eval <- FALSE
      options$highlight <- FALSE
    }
    
    # if this is an exercise setup chunk then eval it if the corresponding
    # exercise chunk is going to be executed
    if (exercise_setup_chunk) {
      
      # figure out the default behavior
      exercise_eval <- knitr::opts_chunk$get('exercise.eval')
      if (is.null(exercise_eval))
        exercise_eval <- FALSE
      
      # look for chunks that name this as their setup chunk
      labels <- exercise_chunks_for_setup_chunk(options$label)
      if (grepl("-setup$", options$label))
        labels <- c(labels, sub("-setup$", "", options$label))
      label_query <- paste0("knitr::all_labels(label %in% ", deparse(labels), ", ",
                            "identical(exercise.eval, ", !exercise_eval, "))")
      
      default_reversed <- length(eval(parse(text = label_query))) > 0
      if (default_reversed)
        exercise_eval <- !exercise_eval
     
      # set the eval property as appropriate
      options$eval <- exercise_eval
    }
    
    # return modified options
    options
  })
  
  # hook to amend output for exercise related chunks
  knitr::knit_hooks$set(tutor = function(before, options, envir) {
    
    # helper to produce an exercise wrapper div w/ the specified class
    exercise_wrapper_div <- function(suffix = NULL, extra_html = NULL) {
      # before exercise
      if (before) {
        if (!is.null(suffix))
          suffix <- paste0("-", suffix)
        class <- paste0("exercise", suffix)
        lines <- ifelse(is.numeric(options$exercise.lines), 
                        options$exercise.lines, 0)
        paste0('<div class="tutor-', class, 
               '" data-label="', options$label, 
               '" data-lines="', lines, '">')
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
        # ensure tutor is initialized
        initialize()
        
        # inject ace dependency
        knitr::knit_meta_add(list(ace_html_dependency()))
        
        # write server code
        exercise_server_chunk(options$label)
      } 
      else {
        # forward a subset of standard knitr chunk options
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
        
        # forward some exercise options
        preserved_options$exercise.df_print <- knitr::opts_knit$get('rmarkdown.df_print')
        if (is.null(preserved_options$exercise.df_print))
          preserved_options$exercise.df_print <- "default"
        preserved_options$exercise.timelimit <- options$exercise.timelimit
        preserved_options$exercise.setup <- options$exercise.setup
        
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
    tutor:::handle_exercise(input$`tutor-exercise-%s-code-editor`)
  })()
})', label, label, label))
}

