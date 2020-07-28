.onLoad <- function(libname, pkgname) {
  register_default_event_handlers()

  # We need an input handler for learnr.exercise, only so that we can call
  # shinytest::registerInputProcessor(), below.
  removeInputHandler("learnr.exercise")
  registerInputHandler("learnr.exercise", function(x, shinysession, name) {
    x
  })


  if ("shinytest" %in% loadedNamespaces()) {
    register_shinytest_inputprocessor()
  }
  setHook(
    packageEvent("shinytest", "onLoad"),
    function(...) register_shinytest_inputprocessor()
  )
}
