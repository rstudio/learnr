
context("storage")

test_that("filesystem storage can be created", {
  fs <- filesystem_storage(tempfile())
  expect_equal(fs$type, "local")
})

test_that("objects cna be saved into filesystem storage", {
  fs <- filesystem_storage(tempfile())
  fs$save_object("tutorial_id", "tutorial_version", "user_id", "object_id", "data")
  obj <- fs$get_object("tutorial_id", "tutorial_version", "user_id", "object_id")
  expect_equal(obj, "data")
  fs$remove_all_objects("tutorial_id", "tutorial_version", "user_id")
})