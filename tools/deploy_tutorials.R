
if (!requireNamespace("remotes")) install.packages("remotes")

# install rsconnect
remotes::install_cran("rsconnect")

# install the latest from master
# must install for packrat to work as expected
remotes::install_github("rstudio/learnr", upgrade = "always", force = TRUE)

remotes::install_cran("renv")
remotes::install_cran(unique(renv::dependencies("inst/tutorials/")$Package))

deploy_app <- function(
  app_dir,
  name = basename(app_dir),
  ...
) {
  cat("\n\n\n")
  message("Deploying: ", name)
  cat("\n")
  rsconnect::deployApp(
    appDir = app_dir,
    appName = name,
    server = "shinyapps.io",
    account = "learnr-examples",
    forceUpdate = TRUE,
    ...
  )
}

deploy_tutorial <- function(
  app_dir,
  doc = dir(app_dir, pattern = "\\.Rmd$")[1],
  name = basename(app_dir)
) {
  deploy_app(
    app_dir = app_dir,
    name = name,
    appPrimaryDoc = doc
  )
}


deploy_folder <- function(path, fn) {
  lapply(
    dir(path, full.names = TRUE),
    function(path) {
      if (dir.exists(path)) {
        fn(path)
      }
    }
  )
}

deploy_folder("inst/tutorials", deploy_tutorial)

message("done")
