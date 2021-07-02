
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


## Commented out because "testServer" can not test anyhting that uses 'session$request'

# td <- tempdir()
#
# server <- function(input, output, session){}
#
# testServer(server, {
#   hs <- hybrid_storage(session, td)
#   context_id <- tutorial_context_id(tutorial_id, tutorial_version)
#   store <- object_store(context_id)
#
#   hs$save_object("tutorial_id", "tutorial_version", "user_id", "object_id", "data")
#
#   # Object is saved in both locations
#   stopifnot(length(list.files(td)) == 1)
#   stopifnot(length(ls(store)) == 1)
#   stopifnot(identical(
#     hs$get_object("tutorial_id", "tutorial_version", "user_id", "object_id"),
#     "data"
#   ))
#
#   # Object is removed from cookies but is still present in filesystem
#   client_storage(session)$remove_all_objects("tutorial_id", "tutorial_version", "user_id")
#   stopifnot(length(ls(store)) == 0)
#   stopifnot(length(list.files(td)) == 1)
#
#   # When objects are pulled in, they are also stored in
#   objs <- hs$get_objects("tutorial_id", "tutorial_version", "user_id")
#   stopifnot(identical(objs, list("data")))
#   stopifnot(length(ls(store)) == 1)
# })
