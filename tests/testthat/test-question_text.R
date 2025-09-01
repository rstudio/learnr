test_that("question text uses textAreaInput if rows or cols are provided", {
  ans <- answer("", TRUE)

  q_textArea_rows <- question_ui_initialize(
    question_text("A", ans, rows = 3),
    ""
  )
  expect_equal(q_textArea_rows$children[[2]]$name, "textarea")
  expect_equal(q_textArea_rows$children[[2]]$attribs$rows, 3)

  q_textArea_cols <- question_ui_initialize(
    question_text("A", ans, cols = 40),
    ""
  )
  expect_equal(q_textArea_cols$children[[2]]$name, "textarea")
  expect_equal(q_textArea_cols$children[[2]]$attribs$cols, 40)

  q_textArea <- question_ui_initialize(
    question_text("A", ans, rows = 4, cols = 30),
    ""
  )
  expect_equal(q_textArea$children[[2]]$name, "textarea")
  expect_equal(q_textArea$children[[2]]$attribs$rows, 4)
  expect_equal(q_textArea$children[[2]]$attribs$cols, 30)

  q_text <- question_ui_initialize(question_text("A", ans), "")
  expect_equal(q_text$children[[2]]$name, "input")
  expect_equal(q_text$children[[2]]$attribs$type, "text")
})

test_that("question_text() answer functions work", {
  q <- question_text(
    text = "test",
    trim = FALSE,
    answer_fn(function(x) {
      if (grepl("[Rr]", x)) {
        incorrect("No R allowed")
      } else {
        correct("good")
      }
    })
  )

  expect_marked_as(
    question_is_correct(q, "problem"),
    correct = FALSE,
    messages = "No R allowed"
  )

  expect_marked_as(
    question_is_correct(q, "cool"),
    correct = TRUE,
    messages = "good"
  )
})

test_that("question_text() evaluates answers in order specified", {
  lifecycle::expect_deprecated(
    question_text(
      text = "test",
      answer("apple"),
      answer("banana", correct = TRUE),
      random_answer_order = TRUE
    )
  )

  q <- question_text(
    text = "test",
    trim = TRUE,
    answer(" R    ", TRUE, "the only good letter"),
    answer_fn(function(x) {
      if (grepl("[Rr]", x)) {
        incorrect("No R allowed")
      } else if (nchar(x) > 2) {
        correct("good")
      }
    })
  )

  # literal answer checked first...
  expect_marked_as(
    question_is_correct(q, "   R   "),
    correct = TRUE,
    messages = quiz_text("the only good letter")
  )

  # followed by answer function answers
  expect_marked_as(
    question_is_correct(q, "problem"),
    correct = FALSE,
    messages = "No R allowed"
  )

  expect_marked_as(
    question_is_correct(q, "cool"),
    correct = TRUE,
    messages = "good"
  )

  # fallback value if literal and answer functions don't match
  expect_marked_as(
    question_is_correct(q, "no"),
    correct = FALSE
  )
})

test_that("question_text() requires some text input", {
  shiny::withReactiveDomain(NULL, {
    q <- question_text(text = "test", answer("R", TRUE))
    expect_error(question_is_correct(q, ""), "text")
  })
})
