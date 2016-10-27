
# run an exercise and return HTML UI
run_exercise <- function(exercise, envir = parent.frame()) {
  
  # get server startup code (used for out-of-proc runners)
  server_start_code <- shiny_prerendered_server_start_code(envir)
  
  # create temp dir for execution (remove on exit)
  exercise_dir <- tempfile(pattern = "tutor-exercise")
  dir.create(exercise_dir)
  oldwd <- setwd(exercise_dir)
  on.exit({
    setwd(oldwd)
    unlink(exercise_dir, recursive = TRUE)
  }, add = TRUE)
  
  # restore knitr options and hooks after knit
  optk <- knitr::opts_knit$get()
  on.exit(knitr::opts_knit$restore(optk), add = TRUE)
  optc <- knitr::opts_chunk$get()
  on.exit(knitr::opts_chunk$restore(optc), add = TRUE)
  hooks <- knitr::knit_hooks$get()
  on.exit(knitr::knit_hooks$restore(hooks), add = TRUE)
  ohooks <- knitr::opts_hooks$get()
  on.exit(knitr::opts_hooks$restore(ohooks), add = TRUE)
  templates <- knitr::opts_template$get()
  on.exit(knitr::opts_template$restore(templates), add = TRUE)
  
  # create new environment for evaluation
  eval_envir <- new.env(parent = envir)
  
  # run setup chunk if necessary
  if (!is.null(exercise$setup))
    eval(parse(text = exercise$setup), envir = eval_envir)
  
  # set preserved chunk options
  knitr::opts_chunk$set(as.list(exercise$options))
  
  # temporarily set knitr options (will be rest by on.exit handlers above)
  knitr::opts_chunk$set(echo = FALSE)
  knitr::opts_chunk$set(comment = NA)
  
  # write the R code to a temp file
  exercise_r <- "exercise.R"
  writeLines(exercise$code, con = exercise_r, useBytes = TRUE)
  
  # spin it
  exercise_rmd <- knitr::spin(hair = exercise_r,
                              knit = FALSE,
                              envir = envir,
                              format = "Rmd")
  
  # create html_fragment output format with forwarded knitr options
  output_format <- rmarkdown::html_fragment(
    fig_width = exercise$options$fig.width,
    fig_height = exercise$options$fig.height,
    fig_retina = exercise$options$fig.retina
  )
  
  # render the R code to markdown + html_dependencies
  output_file <- rmarkdown::render(input = exercise_rmd,
                                   output_format = output_format,
                                   envir = eval_envir,
                                   clean = FALSE,
                                   run_pandoc = FALSE)
  html_dependencies <- attr(output_file, "knit_meta")
  output <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
  
  # render the markdown (respecting html-preserve)
  extracted <- htmltools::extractPreserveChunks(output)
  output <- markdown::markdownToHTML(
    text = extracted$value,
    options = c("use_xhtml", "fragment_only", "base64_images"),
    extensions = markdown::markdownExtensions(),
    fragment.only = TRUE
  )
  output <- htmltools::restorePreserveChunks(output, extracted$chunks)
  
  # return the output as HTML w/ dependencies
  htmltools::attachDependencies(
    htmltools::HTML(output),
    html_dependencies
  )
}

# some concepts

local_inproc_runner <- function() {
  
}

local_shell_runner <- function() {
  
}

local_firejail_runner <- function() {
  
}

local_temp_storage <- function() {
  
}

local_appdir_storage <- function() {
  
}












