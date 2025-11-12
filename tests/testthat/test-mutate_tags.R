has_class <- function(el, .class, ...) {
  class_idx <- which(names(el$attribs) == "class")
  if (!length(class_idx)) {
    return(FALSE)
  }
  el_class <- vapply(
    class_idx,
    function(i) el$attribs[[i]],
    FUN.VALUE = character(1)
  )
  grepl(.class, paste(el_class, collapse = " "), ...)
}

test_that("finalize_tags() finalizes the question UI", {
  q_ui_final <- finalize_question(
    htmltools::div(
      class = "custom-question",
      htmltools::div("answer 1"),
      htmltools::div("answer 2")
    )
  )

  expect_true(has_class(q_ui_final, "question-final"))
  expect_true(has_class(q_ui_final, "disabled"))
  expect_true(has_class(q_ui_final$children[[1]], "disabled"))
  expect_true(has_class(q_ui_final$children[[2]], "disabled"))
  expect_true("disabled" %in% q_ui_final$attribs)
  expect_true("disabled" %in% names(q_ui_final$children[[1]]$attribs))
  expect_true("disabled" %in% names(q_ui_final$children[[2]]$attribs))

  q_ui_checkbox <-
    checkboxGroupInput(
      "q-checkbox",
      label = "check box question",
      choiceValues = letters,
      choiceNames = LETTERS,
      selected = "a"
    )

  q_ui_checkbox_final <- finalize_question(q_ui_checkbox)
  # before
  expect_false(has_class(q_ui_checkbox, "question-final"))
  expect_false(has_class(q_ui_checkbox, "disabled"))
  expect_false("disabled" %in% names(q_ui_checkbox$attribs))
  # after
  expect_true(has_class(q_ui_checkbox_final, "question-final"))
  expect_true(has_class(q_ui_checkbox_final, "disabled"))
  expect_true("disabled" %in% names(q_ui_checkbox_final$attribs))

  q_ui_radio <-
    radioButtons(
      "q-radio",
      label = "radio question",
      choiceValues = letters,
      choiceNames = LETTERS,
      selected = "b"
    )

  q_ui_radio_final <- finalize_question(q_ui_radio)
  # before
  expect_false(has_class(q_ui_radio, "question-final"))
  expect_false(has_class(q_ui_radio, "disabled"))
  expect_false("disabled" %in% names(q_ui_radio$attribs))
  # after
  expect_true(has_class(q_ui_radio_final, "question-final"))
  expect_true(has_class(q_ui_radio_final, "disabled"))
  expect_true("disabled" %in% names(q_ui_radio_final$attribs))
})

test_that("finalize_question() works with a shiny.tag.list, too", {
  q_ui_final <- finalize_question(
    htmltools::tagList(
      htmltools::div("thing 1"),
      htmltools::div("thing 2")
    )
  )

  expect_s3_class(q_ui_final, "shiny.tag.list")
  expect_true(has_class(q_ui_final[[1]], "question-final"))
  expect_true(has_class(q_ui_final[[1]], "disabled"))
  expect_true(has_class(q_ui_final[[2]], "question-final"))
  expect_true(has_class(q_ui_final[[2]], "disabled"))
})
