
if (!requireNamespace("remotes")) {
  install.packages("remotes")
}
remotes::install_cran("rsconnect")

# Set the account info for deployment.
rsconnect::setAccountInfo(
  name   = Sys.getenv("shinyapps_name"), # learnr-examples
  token  = Sys.getenv("shinyapps_token"),
  secret = Sys.getenv("shinyapps_secret")
)

# deploy all tutorials
# deploy using callr with `show = TRUE`
#   to avoid "no output to travis console for 10 mins" error
source("scripts/deploy_apps_on_local.R")
