# Prepares inst/i18n_translations with complete translations
#
# Code borrowed from {pointblank}, thank you @rich-iannone
# https://github.com/rich-iannone/pointblank/blob/master/data-raw/00-reencode_text.R

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

        bytes_nz <- x[x > 0]

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

translations_list <-
  yaml::read_yaml(here::here("data-raw/i18n_translations.yml")) %>%
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

saveRDS(translations_list, file = here("inst/i18n_translations"), version = 2)
