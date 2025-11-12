knitr_engine_caption <- function(engine = NULL) {
  if (is.null(engine)) {
    engine <- "r"
  }

  switch(
    tolower(engine),
    "bash" = "Bash",
    "c" = "C",
    "coffee" = "CoffeeScript",
    "cc" = "C++",
    "css" = "CSS",
    "go" = "Go",
    "groovy" = "Groovy",
    "haskell" = "Haskell",
    "js" = "JavaScript",
    "mysql" = "MySQL",
    "node" = "Node.js",
    "octave" = "Octave",
    "psql" = "PostgreSQL",
    "python" = "Python",
    "r" = "R",
    "rcpp" = "Rcpp",
    "cpp11" = "cpp11",
    "rscript" = "Rscript",
    "ruby" = "Ruby",
    "perl" = "Perl",
    "sass" = "Sass",
    "scala" = "Scala",
    "scss" = "SCSS",
    "sql" = "SQL",
    # else, return as the user provided
    engine
  )
}
