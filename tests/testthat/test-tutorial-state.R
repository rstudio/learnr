
test_that("store works", {
  # First write works
  expect_equal(store_tutorial_cache("myName", c("code", "here"), FALSE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Second write without overwrite is a no-op
  expect_equal(store_tutorial_cache("myName", c("updated", "code"), FALSE), FALSE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("code", "here"))

  # Overwrite returns true
  expect_equal(store_tutorial_cache("myName", c("updated", "code"), TRUE), TRUE)
  expect_equal(tutorial_cache_env$objects[["myName"]], c("updated", "code"))

  # clear clears
  expect_warning(clear_exercise_cache_env(), "deprecated")
  expect_equal(length(get_tutorial_cache("exercise")), 0)
})

test_that("tutorial_cache_works", {
  # 1. Render basic.Rmd
  # 2. Extract prerendered chunks and filter to question/exercise chunks
  # 3. Evaluate the prerendered code to populate the tutorial cache
  # 4. Test the structure of the cache

  basic_rmd <- test_path("tutorials", "basic.Rmd")
  basic_html <- tempfile(fileext = ".html")
  withr::defer(unlink(basic_html))

  install_knitr_hooks()
  withr::defer(remove_knitr_hooks())

  rmarkdown::render(basic_rmd, output_file = basic_html, quiet = TRUE)
  prerendered_chunks <- rmarkdown:::shiny_prerendered_extract_context(
    html_lines = readLines(basic_html),
    context = "server"
  )
  prerendered_chunks <- parse(text = prerendered_chunks)

  is_cache_chunk <- vapply(
    prerendered_chunks,
    function(x) {
      as.character(x[[1]])[3] %in% c("store_exercise_cache", "question_prerendered_chunk")
    },
    logical(1)
  )

  clear_tutorial_cache()
  withr::defer(clear_tutorial_cache())

  res <- vapply(
    prerendered_chunks[is_cache_chunk],
    FUN.VALUE = logical(1),
    function(x) {
      shiny::withReactiveDomain(NULL, {
        session <- shiny::MockShinySession$new()
        eval(x)
        TRUE
      })
    }
  )

  all <- get_tutorial_cache()
  # tutorial cache lists items in order of appearance
  exercises <- c("two-plus-two", "add-function", "print-limit")
  questions <- c("quiz-1", "quiz-2")
  expect_equal(names(all), c(exercises, questions))

  expect_equal(all[exercises], get_exercise_cache())
  expect_equal(all$`two-plus-two`, get_exercise_cache("two-plus-two"))
  expect_true(all(vapply(all[exercises], inherits, logical(1), "tutorial_exercise")))

  expect_equal(all[questions], get_question_cache())
  expect_equal(all$`quiz-2`, get_question_cache("quiz-2"))
  expect_true(all(vapply(all[questions], inherits, logical(1), "tutorial_question")))

  # exercises have the same `global_setup`
  expect_equal(all$`two-plus-two`$global_setup, all$`add-function`$global_setup)
  expect_equal(all$`two-plus-two`$global_setup, all$`print-limit`$global_setup)
  expect_equal(all$`add-function`$options$exercise.lines, 5)
})
