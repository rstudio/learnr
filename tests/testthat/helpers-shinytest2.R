library(shinytest2)

selector_exists <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "document.querySelector('%s') ? true : false",
    selector
  )
}

selector_doesnt_exist <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "document.querySelector('%s') ? false : true",
    selector
  )
}

selector_classlist <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "[...document.querySelector('%s').classList]",
    selector
  )
}

selector_attributes <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "{
const el = document.querySelector('%s')
!el ? {} : el.getAttributeNames()
  .reduce((acc, attr) => {
    acc[attr] = el.getAttribute(attr)
    return acc
  }, {})
}",
    selector
  )
}

selector_coordinates <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "(function() {
      const el = document.querySelector('%s')
      if (!el) {
        return undefined
      }
      const {top, right, bottom, left, width, height, x, y} = el.getBoundingClientRect()
      return {top, right, bottom, left, width, height, x, y}
    })()",
    selector
  )
}

get_editor_value <- function(selector, ...) {
  if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "ace.edit(document.querySelector('%s')).getValue()",
    selector
  )
}

editor_has_focus <- function(selector, ...) {
 if (length(c(...))) {
    selector <- paste(selector, paste(c(...), collapse = " "))
  }
  sprintf(
    "$(':focus')[0] === document.querySelector('%s textarea')",
    selector
  )
}

exercise_selector <- function(id) {
  sprintf(
    "#tutorial-exercise-%s-input",
    id
  )
}

exercise_selector_editor <- function(id) {
  sprintf(
    "%s .ace_editor",
    exercise_selector(id)
  )
}

exercise_selector_hint_btn <- function(id) {
  sprintf(
    "%s .btn-tutorial-hint",
    exercise_selector(id)
  )
}

exercise_selector_run_btn <- function(id) {
  sprintf(
    "%s .btn-tutorial-run",
    exercise_selector(id)
  )
}

exercise_selector_hint_popover <- function(id) {
  sprintf(
    "%s > .tutorial-panel-heading .tutorial-solution-popover",
    exercise_selector(id)
  )
}

exercise_selector_output <- function(id) {
  sprintf(
    "#tutorial-exercise-%s-output",
    id
  )
}

exercise_has_output <- function(id) {
  sprintf(
    "document.querySelector('%s').children.length > 0 ? true : false",
    exercise_selector_output(id)
  )
}

app_real_click <- function(app, selector, ...) {
  chrome <- app$get_chromote_session()

  dims <- app$get_js(selector_coordinates(selector, ...))

  for (event in c("mousePressed", "mouseReleased")) {
    chrome$Input$dispatchMouseEvent(
      type = event,
      x = dims$left + dims$width / 2,
      y = dims$top  + dims$height / 2,
      clickCount = 1,
      pointerType = "mouse",
      button = "left",
      buttons = 1
    )
  }

  invisible(app)
}

if (!"succeed" %in% names(shinytest2::AppDriver$public_methods)) {
  shinytest2::AppDriver$set("public", "succeed", function(...) {
    testthat::succeed(...)
    invisible(self)
  })
}
