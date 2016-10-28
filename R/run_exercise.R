
# run an exercise and return HTML UI
handle_exercise <- function(exercise, envir = parent.frame()) {
  
  # evaluate the exercise 
  result <- evaluate_exercise(exercise, envir)
    
  # return the output as HTML w/ dependencies
  htmltools::attachDependencies(
    htmltools::HTML(result$output),
    result$dependencies
  )
}

# evaluate an exercise and return a list containing output and dependencies
evaluate_exercise <- function(exercise, envir) {
  
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
  
  # run setup chunk if necessary
  if (!is.null(exercise$setup))
    eval(parse(text = exercise$setup), envir = envir)
  
  # set preserved chunk options
  knitr::opts_chunk$set(as.list(exercise$options))
  
  # temporarily set knitr options (will be rest by on.exit handlers above)
  knitr::opts_chunk$set(echo = FALSE)
  knitr::opts_chunk$set(comment = NA)
  
  # write the R code to a temp file
  exercise_r <- "exercise.R"
  writeLines(exercise$code, con = exercise_r, useBytes = TRUE)
  
  # spin it to an Rmd
  exercise_rmd <- knitr::spin(hair = exercise_r,
                              knit = FALSE,
                              envir = envir,
                              format = "Rmd")
  
  # create html_fragment output format with forwarded knitr options
  knitr_options <- rmarkdown::knitr_options_html(
    fig_width = exercise$options$fig.width, 
    fig_height = exercise$options$fig.height,
    fig_retina = exercise$options$fig.retina, 
    keep_md = FALSE
  )
  knitr_options$opts_chunk$error <- TRUE
  knitr_options$knit_hooks$error = function(x, options) {
    msg <- sub(" [^:]+:", ":", x)
    as.character(htmltools::div(class = "tutor-exercise-error", msg))
  }
  output_format <- rmarkdown::output_format(
    knitr = knitr_options,
    pandoc = NULL,
    base_format = rmarkdown::html_fragment(
                    df_print = exercise$options$exercise.df_print
                  )
  )
  
  # knit the Rmd to markdown 
  output_file <- rmarkdown::render(input = exercise_rmd,
                                   output_format = output_format,
                                   envir = envir,
                                   clean = FALSE,
                                   quiet = TRUE,
                                   run_pandoc = FALSE)
  
  # capture the dependenies
  dependencies <- attr(output_file, "knit_meta")
  
  # render the markdown
  output_file <- rmarkdown::render(input = output_file,
                                   output_format = output_format,
                                   envir = envir,
                                   quiet = TRUE,
                                   clean = FALSE)
  output <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
  output <- paste(output, collapse = "\n")
  
  # return result 
  list(output = output,
       dependencies = dependencies)
}

