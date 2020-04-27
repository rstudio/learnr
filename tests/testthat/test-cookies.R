context("cookies")

test_that("cookies are properly serialized", {
  cookies <- structure(list(
      domain = c("httpbin.org", "httpbin.org"),
      flag = c(FALSE, FALSE),
      path = c("/", "/"),
      secure = c(FALSE, FALSE),
      expiration = c(1587586247L, 0L),
      name = c("foo", "bar"),
      value = c("123", "ftw")
    ),
    row.names = c(NA, -2L),
    class = "data.frame")

  f <- tempfile()
  on.exit({unlink(f)})

  write_cookies(cookies, f)
  txt <- readLines(f)
  expect_equal(length(txt), 2)
  expect_equal(txt[1], "httpbin.org\tFALSE\t/\tFALSE\t1587586247\tfoo\t123")
  expect_equal(txt[2], "httpbin.org\tFALSE\t/\tFALSE\t0\tbar\tftw")
})

