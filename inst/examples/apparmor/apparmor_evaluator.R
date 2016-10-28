



# Note: requires adding the following line to /etc/apparmor.d/rapparmor.d/r-user:
#  /usr/lib/rstudio/bin/pandoc/* rix,

# exercise evaluation function
apparmor_evaluate_exercise <- function(expr, timelimit = Inf) {
  RAppArmor::eval.secure(expr, 
                         timeout = timelimit, 
                         profile="r-user") 
}

# install as exercise evaluator
options(tutor.evaluator = apparmor_evaluate_exercise)


