```r
checker <- function(label, user_code, check_code, envir_result, evaluate_result, ...) {
  
  correct <- list(message = "Great job!", correct = TRUE, location = "append")
  incorrect <- list(message = "Code wasn't right!", correct = FALSE, location = "append")
  
  bad_code <- is_bad_code(user_code, check_code)
  
  # this is a code check
  if (is.null(envir_result)) {
    if (bad_code)
      return(incorrect)
    else
      return(TRUE)
  } 
  
  # this is a fully evaluated chunk check
  else if (bad_code) {
    return(incorrect)
  } else {
    return(correct)
  }
}
```