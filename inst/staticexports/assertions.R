is_AsIs <- function(x) {
  inherits(x, "AsIs")
}

is_html_tag <- function(x) {
  inherits(x, c("shiny.tag", "shiny.tag.list"))
}

is_html_chr <- function(x) {
  is.character(x) && inherits(x, "html")
}

is_html_any <- function(x) {
  is_html_tag(x) || is_html_chr(x)
}
