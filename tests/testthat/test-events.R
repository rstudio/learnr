test_that("Event handlers", {
  # Check that session, event, data are passed to callback.
  result <- NULL
  cancel <- event_register_handler("foo",
    function(session, event, data) { result <<- list(session, event, data) }
  )
  on.exit(cancel(), add = TRUE)
  event_trigger("session_obj", "foo", "data")
  expect_identical(result, list("session_obj", "foo", "data"))
  cancel()


  # Testing multiple event handlers for same event, checking for order
  x <- numeric()
  cancel1 <- event_register_handler(
    "foo",
    function(session, event, data) { x <<- c(x, 1) }
  )
  on.exit(cancel1(), add = TRUE)

  cancel2 <- event_register_handler(
    "foo",
    function(session, event, data) { x <<- c(x, 2) }
  )
  on.exit(cancel2(), add = TRUE)

  event_trigger(NULL, "foo", NA)
  expect_identical(x, c(1, 2))

  event_trigger(NULL, "foo", NA)
  expect_identical(x, c(1, 2, 1, 2))

  # Cancel first handler
  expect_true(cancel1())
  expect_false(cancel1())

  event_trigger(NULL, "foo", NA)
  expect_identical(x, c(1, 2, 1, 2, 2))
})


test_that("Event handler input checking", {
  # Should error if callback has incorrect args (session, event, data)
  expect_error(
    event_register_handler("foo", function(session, data) NULL)
  )
  expect_error(
    event_register_handler("foo", function(session, data, event) NULL)
  )

  # Error for empty event name
  expect_error(
    event_register_handler("", function(session, event, data) NULL)
  )
})


test_that("Errors are converted to warnings", {
  n <- 0
  f <- function() g()
  g <- function() stop("error in g")
  cancel1 <- event_register_handler("foo", function(session, event, data) f())
  on.exit(cancel1(), add = TRUE)
  cancel2 <- event_register_handler("foo", function(session, event, data) n <<- n + 1)
  on.exit(cancel2(), add = TRUE)

  expect_warning(event_trigger(NULL, "foo", NA), "error in g")
  # Other callbacks should still have executed.
  expect_identical(n, 1)
})
