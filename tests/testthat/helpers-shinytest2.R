library(shinytest2)

selector_exists <- function(selector) {
  sprintf(
    "document.querySelector('%s') ? true : false",
    selector
  )
}

selector_doesnt_exist <- function(selector) {
  sprintf(
    "document.querySelector('%s') ? false : true",
    selector
  )
}

selector_classlist <- function(selector) {
  sprintf(
    "[...document.querySelector('%s').classList]",
    selector
  )
}

selector_attributes <- function(selector) {
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

get_editor_value <- function(selector) {
  sprintf(
    "ace.edit(document.querySelector('%s')).getValue()",
    selector
  )
}

if (!"succeed" %in% names(AppDriver$public_methods)) {
  AppDriver$set("public", "succeed", function(...) testthat::succeed(...))
}