insert_snippet <- function(key) {
  # <div id="exerciseeval"></div>
  # <script type="text/javascript">loadSnippet('exerciseeval')</script>
  snippet <- readLines(fs::path("../../pkgdown/assets/snippets", key, ext = "md"), warn = FALSE)
  snippet <- paste(snippet, collapse = "\n")
  snippet <- gsub("`", "&#96;", snippet)
  snippet <- htmltools::HTML(snippet)

  htmltools::withTags(
    htmltools::tagList(
      div(
        id = key,
        pre(class = "markdown", code(snippet)),
      ),
      script(type = "text/javascript", htmltools::HTML(sprintf("loadSnippet('%s')", key)))
    )
  )
}