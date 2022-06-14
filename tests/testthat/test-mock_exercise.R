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

test_that("mock_exercise() moves exercise chunk options to default options", {
  ex <- mock_exercise(
    chunks = list(
      mock_chunk(
        label = "chunk-name",
        code = "PASS",
        exercise = TRUE,
        engine = "javascript",
        test_option = "PASS"
      )
    )
  )

  expect_equal(ex$label, "chunk-name")
  expect_equal(ex$code, "PASS")
  expect_equal(ex$engine, "javascript")
  expect_equal(ex$options$test_option, "PASS")

  expect_warning(
    mock_exercise(
      label = "ex",
      chunks = list(
        mock_chunk(
          label = "chunk-name",
          code = "PASS",
          exercise = TRUE,
          engine = "javascript",
          test_option = "PASS"
        )
      )
    )
  )

  expect_warning(
    mock_exercise(
      user_code = "FAIL",
      chunks = list(
        mock_chunk(
          label = "chunk-name",
          code = "PASS",
          exercise = TRUE,
          engine = "javascript",
          test_option = "PASS"
        )
      )
    )
  )

  expect_warning(
    mock_exercise(
      engine = "fail",
      chunks = list(
        mock_chunk(
          label = "chunk-name",
          code = "PASS",
          exercise = TRUE,
          engine = "javascript",
          test_option = "PASS"
        )
      )
    )
  )
})

test_that("mock_exercise() warns if conflicts between arguments and exercise chunk", {
  expect_warning(
    mock_exercise(
      user_code = "1 + 1",
      chunks = list(
        mock_chunk("ex", "2 + 2", exercise = TRUE)
      )
    ),
    "Using `code` from `mock_exercise"
  )

  expect_warning(
    mock_exercise(
      chunks = list(
        mock_chunk("ex", "2 + 2", exercise = TRUE)
      ),
      engine = "python"
    ),
    "Using `engine` from exercise chunk"
  )

  expect_warning(
    mock_exercise(
      chunks = list(
        mock_chunk("ex", "2 + 2", exercise = TRUE)
      ),
      label = "floofy"
    ),
    "Using `label` from exercise chunk"
  )
})

test_that("mock_exercise() resolves multiple exercise chunks", {
  # two exercise chunks, can't resolve which one to use
  expect_error(
    mock_exercise(
      chunks = list(
        mock_chunk("ex", "1 + 1", exercise = TRUE),
        mock_chunk("ex", "2 + 2", exercise = TRUE)
      ),
      label = "ex"
    )
  )

  expect_error(
    mock_exercise(
      chunks = list(
        mock_chunk("ex1", "1 + 1", exercise = TRUE),
        mock_chunk("ex1", "2 + 2", exercise = TRUE)
      ),
      label = "ex"
    )
  )

  # This should probably be a different error, but :shrug:
  expect_error(
    mock_exercise(
      chunks = list(
        mock_chunk("ex1", "1 + 1", exercise = TRUE),
        mock_chunk("ex1", "2 + 2", exercise = TRUE)
      )
    )
  )

  # two exercise chunks, neither matches the provided `label`
  expect_error(
    mock_exercise(
      chunks = list(
        mock_chunk("ex-other", "1 + 1", exercise = TRUE),
        mock_chunk("ex-one", "2 + 2", exercise = TRUE)
      ),
      label = "ex-parent"
    )
  )

  expect_silent(
    mock_exercise(
      chunks = list(
        mock_chunk("ex-other", "1 + 1", exercise = TRUE),
        mock_chunk("ex-parent", "2 + 2", exercise = TRUE)
      ),
      label = "ex-parent"
    )
  )

  # one exercise chunk == that chunk overwrites some arguments
  expect_warning(
    mock_exercise(
      chunks = list(
        mock_chunk("ex", "1 + 1", exercise = TRUE),
        mock_chunk("ex-setup", "2 + 2")
      ),
      label = "ex-parent"
    )
  )
})
