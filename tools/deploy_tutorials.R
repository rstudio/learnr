
if (!requireNamespace("remotes")) install.packages("remotes")

# install rsconnect
remotes::install_cran("rsconnect")

# install the latest from github
# must install for packrat to work as expected
remotes::install_github("rstudio/learnr", upgrade = "always", force = TRUE)

# install missing tutorial deps
remotes::install_cran("renv")
remotes::install_cran(
  setdiff(
    unique(renv::dependencies("inst/tutorials/")$Package),
    unname(installed.packages()[,"Package"])
  )
)

server <- "shinyapps.io"
account <- "learnr-examples"

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
    server = server,
    account = account,
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

deploy_vignettes <- function() {
  lapply(
    dir("vignettes", pattern = ".Rmd", full.names = TRUE),
    function(rmd) {
      rsconnect::deployDoc(
        doc = rmd,
        appName = sub(".Rmd", "", basename(rmd)),
        server = server,
        account = account,
        forceUpdate = TRUE
      )
    }
  )
}

deploy_vignettes()
deploy_folder("inst/tutorials", deploy_tutorial)

message("done")
