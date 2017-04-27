

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
  expect_true(length(q$dependencies) > 0)
})

test_that("questions can be aggregated via quiz", {
  qz <- quiz(
    create_question(),
    create_question(),
    create_question()
  )
  expect_true(length(qz$children) > 0)
})