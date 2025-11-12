test_that("random_phrases()", {
  expect_error(random_phrases("foo"), "should be one of")
  expect_warning(
    expect_equal(
      random_phrases("praise", "foo"),
      random_phrases("praise", "en")
    )
  )

  knitr::opts_knit$set("tutorial.language" = "en")
  expect_equal(random_phrases("praise"), random_phrases("praise", "en"))
  expect_equal(
    random_phrases("encouragement"),
    random_phrases("encouragement", "en")
  )
  knitr::opts_knit$set("tutorial.language" = NULL)

  expect_equal(random_phrases("praise", "testing"), "RANDOM PRAISE.")
  expect_equal(
    random_phrases("encouragement", "testing"),
    "RANDOM ENCOURAGEMENT."
  )
})

test_that("random_phrases_add()", {
  random_phrases_add(
    language = "bogus",
    praise = "Praise here!",
    encouragement = c("Go 1", "Go 2")
  )

  expect_equal(random_phrases("praise", "bogus"), "Praise here!")
  expect_equal(random_phrases("encouragement", "bogus"), c("Go 1", "Go 2"))

  random_phrases_add("bogus", encouragement = "Go 3")
  expect_equal(
    random_phrases("encouragement", "bogus"),
    c("Go 1", "Go 2", "Go 3")
  )

  expect_error(random_phrases_add("bogus", list("bad")))
  expect_error(random_phrases_add("bogus", 1:4))
})
