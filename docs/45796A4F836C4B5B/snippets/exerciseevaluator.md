```r
# exercise evaluation function
apparmor_evaluate_exercise <- function(expr, timelimit) {
  RAppArmor::eval.secure(expr, 
                         timeout = timelimit, 
                         profile="r-user",
                         RLIMIT_NPROC = 1000,
                         RLIMIT_AS = 1024*1024*1024) 
}

# install as exercise evaluator
options(tutor.exercise.evaluator = apparmor_evaluate_exercise)
```
