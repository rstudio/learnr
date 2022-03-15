test_that("split_code_headers()", {
  target <- list(one = "1", two = "2")

  # No whitespace after dashes
  expect_equal(
    split_code_headers(
"# one ----
1
# two ----
2"
    ),
    target
  )


  # Whitespace after first header
  expect_equal(
    split_code_headers(
"# one ----
1
# two ----
2"
    ),
  target
  )

  # Whitespace after subsequent headers
  expect_equal(
    split_code_headers(
"# one ----
1
# two ----
2"
    ),
  target
)

  # Indented
  expect_equal(
    split_code_headers(
      "# one ----
      1
      # two ----
      2"
    ),
    list(one = "      1", two = "      2")
  )
})
