
local({

  ## https://bookdown.org/yihui/rmarkdown/language-engines.html
  # names(knitr::knit_engines$get())
  ##  [1] "awk"         "bash"        "coffee"
  ##  [4] "gawk"        "groovy"      "haskell"
  ##  [7] "lein"        "mysql"       "node"
  ## [10] "octave"      "perl"        "psql"
  ## [13] "Rscript"     "ruby"        "sas"
  ## [16] "scala"       "sed"         "sh"
  ## [19] "stata"       "zsh"         "highlight"
  ## [22] "Rcpp"        "tikz"        "dot"
  ## [25] "c"           "cc"          "fortran"
  ## [28] "fortran95"   "asy"         "cat"
  ## [31] "asis"        "stan"        "block"
  ## [34] "block2"      "js"          "css"
  ## [37] "sql"         "go"          "python"
  ## [40] "julia"       "sass"        "scss"
  ## [43] "theorem"     "lemma"       "corollary"
  ## [46] "proposition" "conjecture"  "definition"
  ## [49] "example"     "exercise"    "proof"
  ## [52] "remark"      "solution"

  languages <- list(
    "r" = "rstudio",
    "rscript" = "rstudio",
    "asis" = NULL,
    "asy" = NULL,
    "awk" = NULL,
    "bash" = "gnubash",
    "block" = NULL,
    "block2" = NULL,
    "c" = "c",
    "cat" = NULL,
    "cc" = "cplusplus",
    "coffee" = "coffeescript",
    "css" = "css3",
    "dot" = NULL,
    "fortran" = NULL,
    "fortran95" = NULL,
    "gawk" = NULL,
    "go" = "go",
    "groovy" = "groovy",
    "haskell" = "haskell",
    "highlight" = NULL,
    "js" = "javascript",
    "julia" = NULL,
    "lein" = NULL,
    "mysql" = "mysql",
    "node" = "node-dot-js",
    "octave" = "octave",
    "perl" = "perl",
    "psql" = "postgresql",
    "python" = "python",
    "Rcpp" = "cplusplus",
    "Rscript" = "rstudio",
    "ruby" = "ruby",
    "sas" = NULL,
    "sass" = "sass",
    "scala" = "scala",
    "scss" = "sass",
    "sed" = NULL,
    "sh" = NULL,
    "sql" = "mariadb",
    "stan" = NULL,
    "stata" = NULL,
    "tikz" = NULL,
    "zsh" = NULL
  )

  knitr_languages <- sort(names(knitr::knit_engines$get()))
  missing_language <- ! (knitr_languages %in% names(languages))
  if (any(missing_language)) {
    stop("Missing a rule for languages: ", paste0(knitr_languages[missing_language], collapse = ", "))
  }

  icon_folder <- file.path("inst", "internals", "icons")

  unlink(icon_folder, recursive = TRUE)
  dir.create(icon_folder, recursive = TRUE)

  pb <- progress::progress_bar$new(
    total = length(languages),
    format = "[:bar] :current / :total :language",
    show_after = 0, clear = TRUE
  )
  Map(format(names(languages)), unname(languages), f = function(language, loc) {
    pb$tick(tokens = list(language = language))
    if (is.null(loc)) return()
    language <- tolower(trimws(language))
    icon_file <- file.path(icon_folder, paste0(language, ".svg"))
    icon_url <- paste0("https://simpleicons.org/icons/", loc, ".svg")
    icon_lines <- readLines(icon_url, warn = FALSE) # missing EOL
    if (length(icon_lines) == 0) stop("Could not download: ", icon_url)
    # will add a trailing line, which makes readLines happy
    writeLines(icon_lines, icon_file)
  })

})
