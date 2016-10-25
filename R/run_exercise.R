
# run an exercise and return HTML UI
run_exercise <- function(exercise, envir = parent.frame()) {
  htmltools::pre(paste(
    exercise$code,
    exercise$setup,
    exercise$check
  ))
}


# get the per-user knitr output path
knitr_output_paths <- function(envir) {
  
  # create output paths if we need to
  if (!exists(".tutor-exercise-knitr-paths", envir = envir)) {
    
    # create the paths
    paths <- list()
    paths$knit <- tempfile(pattern = "tutor-exercise-knit-")
    dir.create(paths$knit)
    paths$fig <- file.path(paths$knit, uuid::UUIDgenerate())
    dir.create(paths$fig)
    
    # add shiny resource path
    shiny::addResourcePath(basename(paths$fig), paths$fig)
    
    # assign them for subsequent reading
    assign(".tutor-exercise-knitr-paths", paths, envir = envir)
  }
  
  # return the output paths
  get(".tutor-exercise-knitr-paths", envir = envir)
}



