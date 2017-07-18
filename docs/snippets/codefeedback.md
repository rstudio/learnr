```r
checker <- function(label, user_code, check_code, envir_result, evaluate_result, ...) {
  
  # this is a code check
  if (is.null(envir_result)) {
    if (is_bad_code(user_code, check_code))
      return(list(message = "Code wasn't right!", correct = FALSE))
    else
      return(TRUE)
  } 
  
  # this is a fully evaluated chunk check
  else {
     list(message = "Great job!", correct = TRUE, location = "append")
  }
}
```