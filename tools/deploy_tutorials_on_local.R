

if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_cran("callr")

# call in separate / non-interactive process
#   to avoid local dev version to be loaded and confuse packrat
callr::r(
  function() {
    source("tools/deploy_tutorials.R")
  },
  show = TRUE
)
