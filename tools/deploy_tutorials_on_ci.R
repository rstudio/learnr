if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_cran("rsconnect")

# Set the account info for deployment.
rsconnect::setAccountInfo(
  name = Sys.getenv("SHINYAPPS_NAME"), # learnr-examples
  token = Sys.getenv("SHINYAPPS_TOKEN"),
  secret = Sys.getenv("SHINYAPPS_SECRET")
)

# deploy all tutorials
# deploy using callr with `show = TRUE`
#   to avoid "no output to travis console for 10 mins" error
source("tools/deploy_tutorials_on_local.R")
