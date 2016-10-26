
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
  
  # get knitr paths
  paths <- knitr_output_paths(envir)
  
  # temporarily set wd
  oldwd <- setwd(paths$knit)
  on.exit(setwd(oldwd), add = TRUE)
  
  # set preserved chunk options
  knitr::opts_chunk$set(as.list(exercise$options))
  
  # temporarily set knitr options (will be rest by on.exit handlers above)
  knitr::opts_chunk$set(echo = FALSE)
  knitr::opts_chunk$set(fig.path=paths$figures)
  
  # spin the R code to markdown
  output <- knitr::spin(report = FALSE,
                        text = exercise$code, 
                        envir = envir, 
                        format ="Rmd")
  
  # render the markdown
  output <- markdown::renderMarkdown(text = output)
  
  # return the output as HTML
  htmltools::HTML(output)
}


# get the per-user knitr output paths
knitr_output_paths <- function(envir) {
  
  # create output paths if we need to
  if (!exists(".tutor-exercise-knitr-paths", envir = envir)) {
    
    # create the paths
    paths <- list()
    paths$knit <- tempfile(pattern = "tutor-exercise-knit-")
    dir.create(paths$knit)
    unique_path_name <- uuid::UUIDgenerate()
    unique_path_name <- sub("^[0-9\\-]*", "", unique_path_name)
    figures_path <- file.path(paths$knit, unique_path_name)
    dir.create(figures_path)
    
    # add shiny resource path
    shiny::addResourcePath(unique_path_name, figures_path)
    
    # return figures path
    paths$figures <- paste0(unique_path_name, "/")
    
    # assign them for subsequent reading
    assign(".tutor-exercise-knitr-paths", paths, envir = envir)
  }
  
  # return the output paths
  get(".tutor-exercise-knitr-paths", envir = envir)
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












