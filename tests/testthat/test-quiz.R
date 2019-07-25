

context("quiz")

create_question <- function() {
  question("Here is a question",
           answer("Answer A"),
           answer("Answer B"),
           answer("Answer C", correct = TRUE)
  )
}

test_that("quiz questions can be created", {
  q <- create_question()
  expect_true(length(q$answers) > 0)

  a <- q$answers[[1]]
  expect_s3_class(a, "tutorial_quiz_answer")
  expect_type(a$id, "character")
  expect_type(a$option, "character")
  expect_s3_class(a$label, "html")
  expect_type(a$correct, "logical")
  expect_type(a$message, "NULL")


  expect_s3_class(q, "learnr_radio")
  expect_s3_class(q, "tutorial_question")

  expect_type(q$type, "character")
  expect_type(q$label, "NULL")

  expect_s3_class(q$question, "html")

  expect_type(q$button_labels, "list")
  expect_s3_class(q$button_labels$submit, "html")
  expect_s3_class(q$button_labels$try_again, "html")

  expect_type(q$messages, "list")
  expect_s3_class(q$messages$correct, "html")
  expect_s3_class(q$messages$try_again, "html")
  expect_s3_class(q$messages$incorrect, "html")
  expect_type(q$messages$message, "NULL")
  expect_type(q$messages$psot_message, "NULL")

  expect_type(q$ids, "list")
  expect_type(q$ids$answer, "character")
  expect_type(q$ids$question, "character")

  expect_s3_class(q$loading, "html")

  expect_type(q$random_answer_order, "logical")

  expect_type(q$allow_retry, "logical")

  expect_type(q$seed, "double")
  expect_type(q$options, "list")
})

test_that("questions can be aggregated via quiz", {
  test_val <- "test value"
  qz <- quiz(
    caption = test_val,
    create_question(),
    create_question(),
    create_question()
  )

  expect_true(length(qz$questions) > 0)
  expect_equal(as.character(qz$caption), test_val)

  expect_s3_class(qz, "tutorial_quiz")
  lapply(qz$questions, expect_s3_class, "tutorial_question")
  expect_s3_class
})
