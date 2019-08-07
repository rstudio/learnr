

callr::r(
  function() {

    # compile readme
    rmarkdown::render("README.Rmd", rmarkdown::github_document(html_preview = FALSE))

    # compile website
    setwd("docs")
    unlink("site_libs", recursive = TRUE)
    rmarkdown::render_site(encoding = 'UTF-8')
  },
  show = TRUE
)
