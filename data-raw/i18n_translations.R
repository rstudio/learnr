# Prepares inst/i18n_translations with complete translations
#
# Code borrowed from {pointblank}, thank you @rich-iannone
# https://github.com/rich-iannone/pointblank/blob/main/data-raw/00-reencode_text.R

library(here)
library(yaml)
library(purrr)
library(stringi)

reencode_utf8 <- function(x) {

  # Ensure that we encode non-UTF-8 strings to UTF-8 in a
  # two-step process: (1) to native encoding, and then
  # (2) to UTF-8
  if (Encoding(x) != 'UTF-8') {
    x <- enc2utf8(x)
  }

  # Use `iconv()` to convert to UTF-32 (big endian) as
  # raw bytes and convert again to integer (crucial here
  # to set the base to 16 for this conversion)
  raw_bytes <-
    iconv(x, "UTF-8", "UTF-32BE", toRaw = TRUE) %>%
    unlist() %>%
    strtoi(base = 16L)

  # Split into a list of four bytes per element
  chars <- split(raw_bytes, ceiling(seq_along(raw_bytes) / 4))

  x <-
    vapply(
      chars,
      FUN.VALUE = character(1),
      USE.NAMES = FALSE,
      FUN = function(x) {

        bytes_nz <- x[min(which(x > 0)):length(x)]

        if (length(bytes_nz) > 2) {
          out <- paste("\\U", paste(as.hexmode(x), collapse = ""), sep = "")
        } else if (length(bytes_nz) > 1) {
          out <- paste("\\u", paste(as.hexmode(bytes_nz), collapse = ""), sep = "")
        } else if (length(bytes_nz) == 1 && bytes_nz > 127) {
          out <- paste("\\u", sprintf("%04s", paste(as.hexmode(bytes_nz)), collapse = ""), sep = "")
        } else {
          out <- rawToChar(as.raw(bytes_nz))
        }
        out
      }
    ) %>%
    paste(collapse = "")

  x
}

# Read raw translations ----
translations_yml <- yaml::read_yaml(here::here("data-raw/i18n_translations.yml"))

# Validate that language keys appear for every translation key ----
translations_lang_keys <-
  translations_yml %>%
  imap(~ set_names(.x, paste0(.y, ".", names(.x)))) %>%
  flatten() %>%
  map(names)

translations_lang_set <- translations_lang_keys %>% reduce(union) %>% sort()

iwalk(translations_lang_keys, function(langs, key) {
  if (!identical(sort(langs), translations_lang_set)) {
    missing_keys <- paste(setdiff(translations_lang_set, langs), collapse = ", ")
    cli::cli_alert_warning("{.code {key}} is missing language(s): {missing_keys}")
  }
})

# Compile translation list for i18next ----
translations_list <-
  translations_yml %>%
  # Drop null keys
  map_depth(2, compact) %>%
  # Re-encode to UTF-8
  map_depth(3, reencode_utf8) %>%
  # Unescape unicode
  map_depth(3, stri_unescape_unicode) %>%
  # Massage into i18next format
  # button$runcode$en -> en$translation$button$runcode
  map_depth(1, transpose) %>%
  transpose() %>%
  map(~ list(translation = .x)) %>%
  # Drop null keys again
  map_depth(3, compact)

saveRDS(translations_list, file = here("inst", "internals", "i18n_translations.rds"), version = 2)

i18n_random_phrases <-
  here("data-raw", "i18n_random-phrases.yml") %>%
  yaml::read_yaml() %>%
  map_depth(3, reencode_utf8) %>%
  map_depth(2, map_chr, stri_unescape_unicode)

saveRDS(i18n_random_phrases, file = here("inst", "internals", "i18n_random_phrases.rds"), version = 2)
