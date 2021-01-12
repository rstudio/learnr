context("Internationalization")

test_that("i18n_translations() are correctly formatted", {
  trns <- i18n_translations()

  expect_type(trns, "list")
  expect_true(!is.null(names(trns)))

  for (lang in names(trns)) {
    expect_equal(length(trns[[lang]]), 1L)
    expect_equal(names(trns[[lang]]), "translation")
    expect_type(trns[[lang]], "list")
  }
})


test_that("i18n_process_language_options() single language", {
  trns <- i18n_process_language_options()
  expect_equal(trns$language, "en")
  expect_equal(trns$resources, i18n_translations())

  trns_xx <- i18n_process_language_options("xx")
  expect_equal(trns_xx$language, "xx")
  expect_equal(trns_xx$resources, i18n_translations())

  trns_yy <- i18n_process_language_options(list(yy = NULL))
  expect_equal(trns_yy$language, "yy")
  expect_equal(trns_yy$resources, i18n_translations())
})

test_that("i18n_process_language_options() single customization", {
  trns <- i18n_process_language_options(list(
    en = list(
      button = list(runcode = "Run"),
      text = list(areyousure = "You sure?")
    )
  ))

  expect_equal(trns$language, "en")
  expect_type(trns$resources$en$custom, "list")
  expect_equal(names(trns$resources$en$custom), c("button", "text"))
  expect_equal(trns$resources$en$custom$button$runcode, "Run")
  expect_equal(trns$resources$en$custom$text$areyousure, "You sure?")
  expect_equal(
    trns$resources$en$translation,
    i18n_translations()$en$translation
  )
})

test_that("i18n_process_language_options() multiple customizations", {
  trns <- i18n_process_language_options(list(
    xx = list(
      button = list(runcode = "XX run"),
      text = list(areyousure = "XX sure")
    ),
    en = list(
      button = list(runcode = "EN run"),
      text= list(areyousure = "EN sure")
    )
  ))

  expect_equal(trns$language, "xx")

  expect_type(trns$resources$xx$custom, "list")
  expect_equal(names(trns$resources$xx$custom), c("button", "text"))
  expect_equal(trns$resources$xx$custom$button$runcode, "XX run")
  expect_equal(trns$resources$xx$custom$text$areyousure, "XX sure")

  expect_type(trns$resources$en$custom, "list")
  expect_equal(names(trns$resources$en$custom), c("button", "text"))
  expect_equal(trns$resources$en$custom$button$runcode, "EN run")
  expect_equal(trns$resources$en$custom$text$areyousure, "EN sure")
  expect_equal(
    trns$resources$en$translation,
    i18n_translations()$en$translation
  )
})

test_that("i18n_process_language_options() json file, all languages", {
  custom <- list(
    ZZ = NULL,
    en = list(
      button = list(runcode = "EN run"),
      text = list(areyousure = "EN sure")
    ),
    "xx" = list(
      button = list(runcode = "XX run"),
      text = list(areyousure = "XX sure")
    )
  )
  tmp_json <- tempfile(fileext = ".json")
  on.exit(unlink(tmp_json))
  jsonlite::write_json(custom, tmp_json, auto_unbox = TRUE)

  trns <- i18n_process_language_options(tmp_json)

  expect_equal(trns$language, "ZZ")

  expect_type(trns$resources$xx$custom, "list")
  expect_equal(names(trns$resources$xx$custom), c("button", "text"))
  expect_equal(trns$resources$xx$custom$button$runcode, "XX run")
  expect_equal(trns$resources$xx$custom$text$areyousure, "XX sure")

  expect_type(trns$resources$en$custom, "list")
  expect_equal(names(trns$resources$en$custom), c("button", "text"))
  expect_equal(trns$resources$en$custom$button$runcode, "EN run")
  expect_equal(trns$resources$en$custom$text$areyousure, "EN sure")
  expect_equal(
    trns$resources$en$translation,
    i18n_translations()$en$translation
  )
})

test_that("i18n_process_language_options() json file, single language", {
  custom_en <- list(
    button = list(runcode = "EN run"),
    text = list(areyousure = "EN sure")
  )
  tmp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(custom_en, tmp_json, auto_unbox = TRUE)
  on.exit(unlink(tmp_json))

  custom <- list(
    ZZ = NULL,
    en = tmp_json,
    "xx" = list(
      button = list(runcode = "XX run"),
      text = list(areyousure = "XX sure")
    )
  )

  trns <- i18n_process_language_options(custom)

  expect_equal(trns$language, "ZZ")

  expect_type(trns$resources$xx$custom, "list")
  expect_equal(names(trns$resources$xx$custom), c("button", "text"))
  expect_equal(trns$resources$xx$custom$button$runcode, "XX run")
  expect_equal(trns$resources$xx$custom$text$areyousure, "XX sure")

  expect_type(trns$resources$en$custom, "list")
  expect_equal(names(trns$resources$en$custom), c("button", "text"))
  expect_equal(trns$resources$en$custom$button$runcode, "EN run")
  expect_equal(trns$resources$en$custom$text$areyousure, "EN sure")
  expect_equal(
    trns$resources$en$translation,
    i18n_translations()$en$translation
  )
})


test_that("i18n_process_language_options() stops if not single character or list with names", {
  expect_error(
    i18n_process_language_options(list("apple", "banana"))
  )
  expect_error(
    i18n_process_language_options(c("apple", "banana"))
  )
  expect_error(
    i18n_process_language_options(list(list(button = list(runcode = "run"))))
  )
})

test_that("i18n_process_language_options() warns if a language is not a single character or list with names", {
  expect_warning(
    i18n_process_language_options(list(en = list(c("foo", "bar"))))
  )
})

test_that("i18n_process_language_options() warns unexpected keys are present", {
  expect_warning(
    i18n_process_language_options(list(en = list(foo = list(), button = list()))),
    "foo"
  )

  expect_warning(
    trns <- i18n_process_language_options(list(
      en = list(
        button = list(foo = "bar", runcode = "run"),
        text = list(baz = "bop", areyousure = "yes")
      )
    ))
  )
  expect_equal(trns$resources$en$custom$button$runcode, "run")
  expect_equal(trns$resources$en$custom$button$foo, "bar")
  expect_equal(trns$resources$en$custom$text$areyousure, "yes")
  expect_equal(trns$resources$en$custom$text$baz, "bop")
})

test_that("i18n_read_json() messages if bad json file", {
  tmpfile <- tempfile(fileext = ".json")
  on.exit(unlink(tmpfile))
  writeLines("foo", tmpfile)
  expect_null(expect_message(i18n_read_json(tmpfile)))
})
