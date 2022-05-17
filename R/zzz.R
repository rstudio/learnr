
# install knitr hooks when package is attached to search path
.onAttach <- function(libname, pkgname) {
  install_knitr_hooks()
  initialize_tutorial()
}

# remove knitr hooks when package is detached from search path
.onDetach <- function(libpath) {
  remove_knitr_hooks()
}

.onLoad <- function(libname, pkgname) {
  register_default_event_handlers()

  # We need an input handler for learnr.exercise, only so that we can call
  # shinytest::registerInputProcessor(), below.
  removeInputHandler("learnr.exercise")
  registerInputHandler("learnr.exercise", function(x, shinysession, name) {
    snapshotPreprocessInput(name, snapshotPreprocessorLearnrExercise)
    x
  })


  if ("shinytest2" %in% loadedNamespaces()) {
    register_shinytest_inputprocessor()
  }
  setHook(
    packageEvent("shinytest2", "onLoad"),
    function(...) register_shinytest_inputprocessor()
  )
}
