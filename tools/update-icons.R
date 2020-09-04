
local({
  languages <- c(
    "R" = "rstudio",
    "Python" = "python",
    # "sqlite" = "sqlite",
    # "MariaDB" = "mariadb",
    "mysql" = "mariadb",
    "Bash" = "gnubash",
    "Rcpp" = "cplusplus",
    # "Stan",
    "js" = "javascript",
    "CSS" = "css3"
  )

  icon_folder <- file.path("inst", "internals", "icons")

  unlink(icon_folder, recursive = TRUE)
  dir.create(icon_folder, recursive = TRUE)

  Map(names(languages), unname(languages), f = function(language, loc) {
    download.file(
      paste0("https://simpleicons.org/icons/", loc, ".svg"),
      file.path(icon_folder, paste0(tolower(language), ".svg"))
    )
  })

})
