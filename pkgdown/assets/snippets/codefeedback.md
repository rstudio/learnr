```r
custom_checker <- function(label, user_code, check_code, envir_result, evaluate_result, last_value, ...) {
  if (is.null(envir_result)) {
    # check_code contains `*-code-check` code
    if (is_bad_code(user_code, check_code)) {
      return(list(message = "I wasn't expecting that code", correct = FALSE))
    }
    return(list(message = "Nice code!", correct = TRUE))
  }
  
  # check_code contains `*-check` code
  if (is_bad_result(last_value, check_code)) {
    return(list(message = "I wasn't expecting that result", correct = FALSE))
  }
  list(message = "Great job!", correct = TRUE, location = "append")
}

tutorial_options(exercise.checker = custom_checker)
```