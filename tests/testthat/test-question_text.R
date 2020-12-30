test_that("question text uses textAreaInput if rows or cols are provided", {
  ans <- answer("", TRUE)

  q_textArea_rows <- question_ui_initialize(question_text("A", ans, rows = 3), "")
  expect_equal(q_textArea_rows$children[[2]]$name, "textarea")
  expect_equal(q_textArea_rows$children[[2]]$attribs$rows, 3)

  q_textArea_cols <- question_ui_initialize(question_text("A", ans, cols = 40), "")
  expect_equal(q_textArea_cols$children[[2]]$name, "textarea")
  expect_equal(q_textArea_cols$children[[2]]$attribs$cols, 40)

  q_textArea <- question_ui_initialize(question_text("A", ans, rows = 4, cols = 30), "")
  expect_equal(q_textArea$children[[2]]$name, "textarea")
  expect_equal(q_textArea$children[[2]]$attribs$rows, 4)
  expect_equal(q_textArea$children[[2]]$attribs$cols, 30)

  q_text <- question_ui_initialize(question_text("A", ans), "")
  expect_equal(q_text$children[[2]]$name, "input")
  expect_equal(q_text$children[[2]]$attribs$type, "text")
})
