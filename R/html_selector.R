
# only handles id and classes
as_selector <- function(selector) {
  if (inherits(selector, "shiny_selector") || inherits(selector, "shiny_selector_list")) {
    return(selector)
  }

  # make sure it's a trimmed string
  selector <- str_trim(selector)

  # yell if there is a comma
  if (grepl(",", selector, fixed = TRUE)) {
    stop("Do not know how to handle comma separated selector values")
  }

  # if it contains multiple elements, recurse
  if (grepl(" ", selector)) {
    selector <- lapply(strsplit(selector, "\\s+"), as_selector)
    selector <- structure(class = "shiny_selector_list", selector)
    return(selector)
  }

  match_everything <- isTRUE(all.equal(selector, "*"))

  element <- str_match(selector, "^([^#.]+)")
  selector <- str_remove(selector, "^[^#.]+")

  id <- str_remove(str_match(selector, "^#([^.]+)"), "#")
  selector <- str_remove(selector, "^#[^.]+")

  classes <- str_remove(str_match_all(selector, "\\.([^.]+)"), "^\\.")

  structure(class = "shiny_selector", list(
    element = element,
    id = id,
    classes = classes,
    match_everything = match_everything
  ))
}

as_selector_list <- function(selector) {
  selector <- as_selector(selector)
  if (inherits(selector, "shiny_selector")) {
    selector <- structure(class = "shiny_selector_list", list(selector))
  }
  selector
}

format.shiny_selector <- function(x, ...) {
  if (x$match_everything) {
    paste0("* // match everything")
  } else {
    paste0(x$element, if (!is.null(x$id)) paste0("#", x$id), paste0(".", x$classes, collapse = ""))
  }
}
format.shiny_selector_list <- function(x, ...) {
  paste0(unlist(lapply(x, format, ...)), collapse = " ")
}

print.shiny_selector <- function(x, ...) {
  cat("// css selector\n")
  cat(format(x, ...), "\n")
}
print.shiny_selector_list <- function(x, ...) {
  cat("// css selector list\n")
  cat(format(x, ...), "\n")
}
