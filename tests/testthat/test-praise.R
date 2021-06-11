test_that("random_phrases()", {
  expect_error(random_phrases("foo"), "should be one of")
  expect_warning(
    expect_equal(random_phrases("praise", "foo"), random_phrases("praise", "en"))
  )

  knitr::opts_knit$set("tutorial.language" = "en")
  expect_equal(random_phrases("praise"), random_phrases("praise", "en"))
  expect_equal(random_phrases("encouragement"), random_phrases("encouragement", "en"))
  knitr::opts_knit$set("tutorial.language" = NULL)

  expect_equal(random_phrases("praise", "debug"), "RANDOM PRAISE.")
  expect_equal(random_phrases("encouragement", "debug"), "RANDOM ENCOURAGEMENT.")
})
