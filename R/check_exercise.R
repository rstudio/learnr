#' Check the code from an Exercise
#'
#' This function will take all the chunks with a label that matches `setup` or
#' `-solution`, put them in a separate script and try to run them all.
#' This allows teachers to check that their setup and solution chunks
#' contain valid code.
#'
#' @param path Path to the Markdown file containing the RMarkdown.
#' @param verbose Should the test output information on the console?
#'
#' @return TRUE or FALSE invisibly.
#' @export
#'
#' @examples
#' if (interactive()){
#'   check_exercise("sandbox/sandbox.Rmd")
#' }
check_exercise <- function(
  path,
  verbose = TRUE
){
  # Create a file that will receive the chunks
  tempr <- tempfile(fileext = ".R")
  write_there <- function(x){
    write(
      x,
      tempr,
      append = TRUE
    )
  }

  # Getting the old chunk hook, and reset it on exit
  hook_old <- knitr::knit_hooks$get("chunk")
  on.exit(
    knitr::knit_hooks$set(chunk = hook_old)
  )

  # Setting a hook on every chunk
  knitr::knit_hooks$set(chunk = function(x, options) {
    # It the chunk is a setup or solution chunk, we add it to
    # the temp .R script
    if(grepl("(\\-*setup|\\-solution)$", options$label)){
      write_there(
        sprintf(
          "# %s ----",
          options$label
        )
      )
      if (verbose){
        write_there(
          sprintf(
            'cli::cat_rule("Checking chunk %s")',
            options$label
          )
        )
      }
      write_there(
        options$code
      )
      if (verbose){
        write_there(
          'cli::cat_bullet("Ok", col = "green", bullet = "tick");cli::cat_line(" ")'
        )
      }
    }
    hook_old(x, options)
  })

  # Trick knitr into thinking we are in a shiny_prerender context
  hook_runtime<- knitr::knit_hooks$get("rmarkdown.runtime")
  on.exit(
    knitr::knit_hooks$set("rmarkdown.runtime" = hook_runtime)
  )
  knitr::opts_knit$set(rmarkdown.runtime = "shiny_prerendered")

  # We don't need the knitted output so we unlink it immediatly
  unlink(knitr::knit(path, quiet = TRUE))

  # Trying to source the temp R script
  tc <- try( source(tempr) )
  unlink(tempr)

  cli::cat_line(" ")
  cli::cat_rule("Check finished")
  cli::cat_line(" ")

  if (
    inherits(tc, "try-error")
  ){
    cli::cat_bullet(
      "Running setup and/or solution chunks failed",
      col = "red",
      bullet = "cross"
    )
    return(invisible(FALSE))
  }

  cli::cat_bullet(
    "Successfully run setup and/or solution chunks",
    col = "green",
    bullet = "tick"
  )

  cli::cat_line(" ")

  return(invisible(TRUE))
}
