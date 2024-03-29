skip_if_lang_is_c <- function() {
  # See rstudio/learnr#800
  # Treat C.UTF-8 locale like C locale (BZ# 16621)
  #
  #  The wiki page https://sourceware.org/glibc/wiki/Proposals/C.UTF-8
  #  says that "Setting LC_ALL=C.UTF-8 will ignore LANGUAGE just like it
  #  does with LC_ALL=C." This patch implements it.
  #
  # The Debian checks use LANG=C.UTF-8, which now works "like the C locale",
  # so messages will no longer be translated.

  if (Sys.getenv("LANG") == "C.UTF-8") {
    skip("Skipping test because LANG is C.UTF-8")
  }
  if (Sys.getenv("LANG") == "C") {
    skip("Skipping test because LANG is C")
  }
  if (Sys.getenv("LC_ALL") == "C.UTF-8") {
    skip("Skipping test because LC_ALL is C.UTF-8")
  }
  if (Sys.getenv("LC_ALL") == "C") {
    skip("Skipping test because LC_ALL is C")
  }
}
