
# run an exercise and return HTML UI
run_exercise <- function(exercise, envir = parent.frame()) {
  
  # restore knitr options and hooks after knit
  optk <- knitr::opts_knit$get()
  on.exit(knitr::opts_knit$restore(optk), add = TRUE)
  optc <- knitr::opts_chunk$get()
  on.exit(knitr::opts_chunk$restore(optc), add = TRUE)
  hooks <- knitr::knit_hooks$get()
  on.exit(knitr::knit_hooks$restore(hooks), add = TRUE)
  ohooks <- knitr::opts_hooks$get()
  on.exit(knitr::opts_hooks$restore(ohooks), add = TRUE)
  templates <- knitr::opts_template$get()
  on.exit(knitr::opts_template$restore(templates), add = TRUE)
  
  # get server startup code (used for out-of-proc runners)
  server_start_code <- shiny_prerendered_server_start_code(envir)
  
  # create new environment for evaluation
  eval_envir <- new.env(parent = envir)
  
  # temporarily set wd to session knitr dir
  oldwd <- setwd(session_knitr_dir(envir))
  on.exit(setwd(oldwd), add = TRUE)
  
  # run setup chunk if necessary
  if (!is.null(exercise$setup))
    eval(parse(text = exercise$setup), envir = eval_envir)
  
  # set preserved chunk options
  knitr::opts_chunk$set(as.list(exercise$options))
  
  # temporarily set knitr options (will be rest by on.exit handlers above)
  knitr::opts_chunk$set(echo = FALSE)
  knitr::opts_chunk$set(comment = NA)
  knitr::opts_chunk$set(screenshot.force = FALSE)
  
  # reset knit_meta (and ensure it's reset again when we exit)
  knitr::knit_meta(clean = TRUE)
  on.exit(knitr::knit_meta(clean = TRUE), add = TRUE)
  
  # spin the R code to markdown
  output <- knitr::spin(report = FALSE,
                        text = exercise$code, 
                        envir = eval_envir, 
                        format = "Rmd")
  
  # collect html dependencies
  html_dependencies <- knitr::knit_meta(class = "html_dependency")
  
  # render the markdown (respecting html-preserve)
  extracted <- htmltools::extractPreserveChunks(output)
  output <- markdown::markdownToHTML(
    text = extracted$value,
    options = c("use_xhtml", "fragment_only", "base64_images"),
    extensions = markdown::markdownExtensions(),
    fragment.only = TRUE
  )
  output <- htmltools::restorePreserveChunks(output, extracted$chunks)
  
  # return the output as HTML w/ dependencies
  htmltools::attachDependencies(
    htmltools::HTML(output),
    html_dependencies
  )
}


# get the per-session knitr dir
session_knitr_dir <- function(envir) {
  
  # create knitr dir
  if (!exists(".tutor-session-knitr-dir", envir = envir)) {
    
    # create the directory
    dir <- tempfile(pattern = "tutor-session-knitr-dir")
    dir.create(dir)
   
    # assign for subsequent reading
    assign(".tutor-session-knitr-dir", dir, envir = envir)
  }
  
  # return the knitr dir
  get(".tutor-session-knitr-dir", envir = envir)
}



# some concepts

local_inproc_runner <- function() {
  
}

local_shell_runner <- function() {
  
}

local_firejail_runner <- function() {
  
}

local_temp_storage <- function() {
  
}

local_appdir_storage <- function() {
  
}












