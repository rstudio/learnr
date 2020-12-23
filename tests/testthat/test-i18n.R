context("Internationalization")

test_that("tutorial_i18n_custom_language()", {
  custom_en <- tutorial_i18n_custom_language(
    language = "en",
    button = list(runcode = "Run!"),
    text = list(startover = "Restart!")
  )

  expect_equal(names(custom_en), "en")
  expect_equal(names(custom_en$en), "custom")
  expect_equal(names(custom_en$en$custom), c("button", "text"))
  expect_equal(custom_en$en$custom$button$runcode, "Run!")
  expect_null(custom_en$en$custom$button$hints)
})

test_that("tutorial_i18n_custom_language() warns about unexpected translation keys", {
  # warns about unexpected translation keys, but passes them through
  expect_warning(
    custom_extra <- tutorial_i18n_custom_language(button = list(foo = "unknown", hints = "H"))
  )
  expect_equal(custom_extra$en$custom$button$foo, "unknown")
  expect_equal(custom_extra$en$custom$button$hints, "H")
})

test_that("tutorial_i18n_custom_language() returns NULL if no customizations", {
  # No options returns NULL
  expect_silent(expect_null(tutorial_i18n_custom_language()))
  expect_null(tutorial_i18n_custom_language("es"))
})

test_that("tutorial_i18n_translations() are correctly formatted", {
  trns <- tutorial_i18n_translations()

  expect_type(trns, "list")
  expect_true(!is.null(names(trns)))

  for (lang in names(trns)) {
    expect_equal(length(trns[[lang]]), 1L)
    expect_equal(names(trns[[lang]]), "translation")
    expect_type(trns[[lang]], "list")
  }
})

test_that("tutorial_i18n_process_language_options() single language", {
  trns <- tutorial_i18n_process_language_options()
  expect_equal(trns$default, "en")
  expect_equal(trns$translations, tutorial_i18n_translations())

  trns_en <- tutorial_i18n_process_language_options("en")
  expect_equal(trns_en$default, "en")
  expect_equal(trns_en$translations, tutorial_i18n_translations())

  trns_es <- tutorial_i18n_process_language_options(list(default = "es"))
  expect_equal(trns_es$default, "es")
  expect_equal(trns_es$translations, tutorial_i18n_translations())
})

test_that("tutorial_i18n_process_language_options() single customization", {
  trns <- tutorial_i18n_process_language_options(list(
    custom = list(
      button = list(runcode = "Run"),
      text = list(areyousure = "You sure?")
    )
  ))

  expect_equal(trns$default, "en")
  expect_type(trns$translations$en$custom, "list")
  expect_equal(names(trns$translations$en$custom), c("button", "text"))
  expect_equal(trns$translations$en$custom$button$runcode, "Run")
  expect_equal(trns$translations$en$custom$text$areyousure, "You sure?")
  expect_equal(
    trns$translations$en$translation,
    tutorial_i18n_translations()$en$translation
  )

  trns_xx <- tutorial_i18n_process_language_options(list(
    default = "xx",
    custom = list(
      text = list(areyousure = "Sure?")
    )
  ))

  expect_equal(trns_xx$default, "xx")
  expect_type(trns_xx$translations$xx$custom, "list")
  expect_equal(names(trns_xx$translations$xx$custom), "text")
  expect_null(trns_xx$translations$xx$custom$button)
  expect_equal(trns_xx$translations$xx$custom$text$areyousure, "Sure?")

  trns_zz <- tutorial_i18n_process_language_options(list(
    default = "xx",
    custom = list(
      language = "zz",
      button = list(runcode = "Run")
    )
  ))

  expect_equal(trns_zz$default, "xx")
  expect_type(trns_zz$translations$zz$custom, "list")
  expect_equal(names(trns_zz$translations$zz$custom), "button")
  expect_equal(trns_zz$translations$zz$custom$button$runcode, "Run")
  expect_null(trns_zz$translations$zz$custom$text)
})

test_that("tutorial_i18n_process_language_options() multiple customizations", {
  trns <- tutorial_i18n_process_language_options(list(
    default = "xx",
    custom = list(
      list(
        button = list(runcode = "XX run"),
        text = list(areyousure = "XX sure")
      ),
      list(
        language = "en",
        button = list(runcode = "EN run"),
        text= list(areyousure = "EN sure")
      )
    )
  ))

  expect_equal(trns$default, "xx")

  expect_type(trns$translations$xx$custom, "list")
  expect_equal(names(trns$translations$xx$custom), c("button", "text"))
  expect_equal(trns$translations$xx$custom$button$runcode, "XX run")
  expect_equal(trns$translations$xx$custom$text$areyousure, "XX sure")

  expect_type(trns$translations$en$custom, "list")
  expect_equal(names(trns$translations$en$custom), c("button", "text"))
  expect_equal(trns$translations$en$custom$button$runcode, "EN run")
  expect_equal(trns$translations$en$custom$text$areyousure, "EN sure")
  expect_equal(
    trns$translations$en$translation,
    tutorial_i18n_translations()$en$translation
  )
})

test_that("tutorial_i18n_process_language_options() json file", {
  custom <- c(
    tutorial_i18n_custom_language(
      language = "en",
      button = list(runcode = "EN run"),
      text = list(areyousure = "EN sure")
    ),
    tutorial_i18n_custom_language(
      language = "xx",
      button = list(runcode = "XX run"),
      text = list(areyousure = "XX sure")
    )
  )
  tmp_json <- tempfile(fileext = ".json")
  on.exit(unlink(tmp_json))
  jsonlite::write_json(custom, tmp_json, auto_unbox = TRUE)

  trns <- tutorial_i18n_process_language_options(list(
    default = "ZZ",
    custom = tmp_json
  ))

  expect_equal(trns$default, "ZZ")

  expect_type(trns$translations$xx$custom, "list")
  expect_equal(names(trns$translations$xx$custom), c("button", "text"))
  expect_equal(trns$translations$xx$custom$button$runcode, "XX run")
  expect_equal(trns$translations$xx$custom$text$areyousure, "XX sure")

  expect_type(trns$translations$en$custom, "list")
  expect_equal(names(trns$translations$en$custom), c("button", "text"))
  expect_equal(trns$translations$en$custom$button$runcode, "EN run")
  expect_equal(trns$translations$en$custom$text$areyousure, "EN sure")
  expect_equal(
    trns$translations$en$translation,
    tutorial_i18n_translations()$en$translation
  )
})

test_that("tutorial_i18n_prepare_language_file()", {
  path <- tutorial_i18n_prepare_language_file(list(
    default = "DEFAULT",
    custom = list(
      language = "LL",
      button = list(runcode = "RUNCODE"),
      text = list(areyousure = "YOU SURE")
    )
  ))
  on.exit(unlink(path))
  text <- readLines(path)
  expect_equal(sum(grepl("lng: 'DEFAULT'", text, fixed = TRUE)), 1)
  expect_equal(sum(grepl('"LL":{"custom":', text, fixed = TRUE)), 1)
  expect_equal(sum(grepl('"button":{"runcode":"RUNCODE"}', text, fixed = TRUE)), 1)
  expect_equal(sum(grepl('"text":{"areyousure":"YOU SURE"}', text, fixed = TRUE)), 1)
})