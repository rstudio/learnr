
# run an exercise and return HTML UI
run_exercise <- function(exercise) {
  htmltools::pre(paste(
    exercise$code,
    exercise$setup,
    exercise$check
  ))
}

