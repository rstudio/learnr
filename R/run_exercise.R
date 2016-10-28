


# run an exercise and return HTML UI
handle_exercise <- function(exercise, envir = parent.frame()) {
  
  # determine the exercise runner
  runner <- getOption("tutor.runner", default = "internal")

  if (runner == "internal") {
    
    # evaluate the exercise in process
    result <- evaluate_exercise(exercise, envir)
    
  }  
  else {
    
    # get server startup code and prepend it to the exercise setup code
    server_start_code <- shiny_prerendered_server_start_code(envir)
    exercise$setup <- paste(c(server_start_code, exercise$setup), collapse = "\n")
    
    # setup temp json input and output files for external call
    input_file <- tempfile(pattern = "tutor-exercise-input", fileext = ".json")
    output_file <- tempfile(pattern = "tutor-exercise-output", fileext = ".json")
    on.exit(file.remove(c(input_file, output_file)), add = TRUE)
    
    # serialize as JSON then write to input_file
    exercise_json <- jsonlite::serializeJSON(exercise)
    writeLines(exercise_json, con = input_file, useBytes = TRUE)
    
    # launch an external R process to handle the request
    if (runner == "external") {
      cmd <- sprintf("tutor::run_exercise('%s', '%s')", input_file, output_file)
      code <- system2(command = file.path(R.home('bin'), "R"), 
                      args = c("--slave", "--vanilla", "-e", shQuote(cmd)))
    } else {
      code <- system2(runner, args = c(input_file, output_file))
    }
    if (code != 0)
      stop("Error ", code, " executing exercise via '", runner, "'")
  
    # read the output_file
    result_json <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
    result <- jsonlite::unserializeJSON(result_json)
  }
  
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


#' Run an exercise and return it's results
#' 
#' Run a JSON serialiazed exercise and return the results as JSON.
#' 
#' @param input Path to file containing input JSON
#' @param output Path to file to write output JSON
#'
#' @export 
run_exercise <- function(input, output) {
  
  # read the json from the input file
  exercise_json <- readLines(input, warn = FALSE, encoding = "UTF-8")
  exercise <- jsonlite::unserializeJSON(exercise_json)
  
  # evalate the exercise
  result <- evaluate_exercise(exercise, new.env())
  
  # write the results as json (write then move so the caller can
  # check for file existence as an indicator that we are done)
  result_json <- jsonlite::serializeJSON(result)
  output_stage <- tempfile(pattern = "tutor-exercise-result-stage", 
                           tmpdir = dirname(output),
                           fileext = ".json")
  writeLines(result_json, con = output_stage, useBytes = TRUE)
  file.rename(output_stage, output)
  
  # return nothing
  invisible(NULL)
}

