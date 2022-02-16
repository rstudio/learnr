test_that("exercise mocks: mock_prep_setup()", {
  chunks <- list(
    mock_chunk("setup-1", "x <- 1"),
    mock_chunk("setup-2", "y <- 2", exercise.setup = "setup-1"),
    mock_chunk("setup-3", "z <- 3", exercise.setup = "setup-2")
  )
  expect_equal(mock_prep_setup(chunks, "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks, "setup-2"), "x <- 1\ny <- 2")
  expect_equal(mock_prep_setup(chunks, "setup-1"), "x <- 1")

  # random order
  expect_equal(mock_prep_setup(chunks[3:1], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(1, 3, 2)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(2, 3, 1)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")
  expect_equal(mock_prep_setup(chunks[c(2, 1, 3)], "setup-3"), "x <- 1\ny <- 2\nz <- 3")

  # checks that setup chunk is in chunks
  expect_error(mock_prep_setup(chunks, "setup-Z"), "setup-Z")

  # cycles
  chunks[[1]]$opts$exercise.setup = "setup-3"
  expect_error(mock_prep_setup(chunks, "setup-3"), "-> setup-3$")

  # duplicate labels
  expect_error(mock_prep_setup(chunks[c(1, 1)], "setup-1"), "Duplicated")
})

test_that("mock_exercise() creates tests with splits", {
  code <- '1 + 1

# one plus two ----
1 + 2

## one plus three ----
1 + 3

#### one equals three ----
1 = 3

# 2 minus one ----
2 - 1'

  ex <- mock_exercise("1 + 1", tests = code)
  expect_equal(
    ex$tests,
    list(
      test00 = "1 + 1",
      "one plus two" = "1 + 2",
      "one plus three" = "1 + 3",
      "one equals three" = "1 = 3",
      "2 minus one" = "2 - 1"
    )
  )
})

test_that("mock_exercise() tests, no splits", {
  expect_null(mock_exercise("1 + 1")$tests)
  expect_equal(mock_exercise("1 + 1", tests = "1 + 1")$tests, list("1 + 1"))
})

test_that("mock_exercise() tests, bad split", {
  code <- '   ## one\npi'
  expect_equal(mock_exercise("1 + 1", tests = code)$tests, list(code))
})
