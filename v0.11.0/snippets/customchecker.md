```r
custom_checker <- function(label, user_code, check_code, envir_result, evaluate_result, last_value, stage, ...) {
  # this is a code check
  if (stage == "code_check") {
    if (is_bad_code(user_code, check_code)) {
      return(list(message = "I wasn't expecting that code", correct = FALSE))
    }
    return(list(message = "Nice code!", correct = TRUE))
  }
  # this is a fully evaluated chunk check
  if (is_bad_result(last_value, check_code)) {
    return(list(message = "I wasn't expecting that result", correct = FALSE))
  }
  list(message = "Great job!", correct = TRUE, location = "append")
}

tutorial_options(exercise.checker = custom_checker)
```
