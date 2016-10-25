
# run an exercise and return HTML UI
run_exercise <- function(exercise, envir = parent.frame()) {
  htmltools::pre(paste(
    exercise$code,
    exercise$setup,
    exercise$check
  ))
}


# get the per-user session figure path
knitr_figure_path <- function(envir) {
  
  # create figure path if we need to
  if (!exists("tutor-exercise-figure-path", envir = envir)) {
    figure_path <- tempfile(pattern = "tutor-exercise-figures")
    dir.create(figure_path)
    shiny::addResourcePath(basename(figure_path), figure_path)
    assign("tutor-exercise-figure-path", figure_path, envir = envir)
  }
  
  # return the figure path
  get("tutor-exercise-figure-path", envir = envir)
}



