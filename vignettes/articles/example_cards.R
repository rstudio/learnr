card <- function(title, link, image, alt = NULL, text = NULL, footer = NULL, ...) {
  alt <- alt %||% paste0("Preview image of ", title)

  bslib::card(
    bslib::card_image(file = image, href = link, alt = alt),
    bslib::card_title(htmltools::a(href = link, title)),
    if (!is.null(text)) htmltools::HTML(commonmark::markdown_html(text)),
    if (!is.null(footer)) 
      bslib::card_footer(htmltools::HTML(footer)),
  )
}

example_cards <- function(yml, group) {
  examples <- if (is.list(yml)) {
    yml
  } else {
    yaml::read_yaml(yml)
  }

  examples <- purrr::keep(examples, function(x) x[["group"]] %in% group)
  cards <- purrr::map(examples, function(x) purrr::exec(card, !!!x))

  bslib::layout_column_wrap(!!!cards)
}
