card <- function(...) {
  card_data <- list(...)
  htmltools::withTags(
    div(
      class = "col",
      div(
        class = "card h-100 shadow-sm",
        a(
          href = card_data$link,
          img(
            src = card_data$image,
            class = "card-img-top",
            alt = paste0("Preview image of ", card_data$title)
          )
        ),
        div(
          class = "card-body",
          h5(class = "card-title", a(href = card_data$link, card_data$title)),
          if (!is.null(card_data$text)) div(
            class = "card-text text-muted fs-6",
            htmltools::HTML(commonmark::markdown_html(card_data$text))
          ),
        ),
        if (!is.null(card_data$footer)) div(
          class = "card-footer text-end",
          htmltools::HTML(card_data$footer)
        )
      )
    )
  )
}

example_cards <- function(yml, group = NULL, cols = "row-cols-1 row-cols-md-2 row-cols-lg-3") {
  examples <- if (is.list(yml)) {
    yml
  } else {
    yaml::read_yaml(yml)
  }

  examples <- purrr::keep(examples, function(x) x[["group"]] == group)
  examples <- purrr::transpose(examples)

  htmltools::tags$div(
    class = paste("row g-4", cols),
    purrr::pmap(examples, card)
  )
}
