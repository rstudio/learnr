
str_trim <- function(x, side = "both", character = "\\s") {
  if (side %in% c("both", "left", "start")) {
    rgx <- sprintf("^%s+", character)
    x <- sub(rgx, "", x)
  }
  if (side %in% c("both", "right", "end")) {
    rgx <- sprintf("%s+$", character)
    x <- sub(rgx, "", x)
  }
  x
}
