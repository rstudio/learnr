

# install rmarkdown.onKnit hook when package is attached to search path
.onAttach <- function(libname, pkgname) {
  setHook("rmarkdown.onKnit", install_knitr_hooks, action = "append")
}

install_knitr_hooks <- function(input, runtime) {

  # don't attach hooks if the runtime isn't shiny_prerendered
  if (!identical(runtime, "shiny_prerendered"))
    return(NULL)

  is_exercise <- function(options) {
    isTRUE(options[["exercise"]])
  }
  is_exercise_support <- function(options) {
    grepl("^.*-(setup|evaluate)$", options$label)
  }

  # option hook to turn off evaluation for exercise related chunks
  default_eval_hook <- knitr::opts_hooks$get("eval")
  knitr::opts_hooks$set(eval = function(options) {

    # call default if we have one
    if (!is.null(default_eval_hook))
      options <- default_eval_hook(options)

    # if this is an exercise or exercise support then don't eval it
    if (is_exercise(options) || is_exercise_support(options))
      options$eval = FALSE

    # return modified options
    options
  })

  # source hook
  default_source_hook <- knitr::knit_hooks$get("source")
  knitr::knit_hooks$set(source = function(x, options) {
    if (is_exercise(options)) {
      x
    }
    else if (is_exercise_support(options)) {
      paste0(options$label, ": ", x)
    }
    else
      default_source_hook(x, options)
  })


}


