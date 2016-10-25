
#' Run an Exercise
#' 
#' @param exercise Exercise input from client
#' 
#' @return HTML UI with results of exercise
#' 
#' @keywords internal
#' @export
run_exercise <- function(exercise) {
  htmltools::pre(exercise$code)
}

