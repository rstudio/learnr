#' Tutorial document format
#' 
#' Long-form tutorial which includes narrative, figures, videos, exercises, and
#' questions.
#' 
#' @inheritParams rmarkdown::html_document
#'   
#' @param theme Visual theme ("rstudio", default", "cerulean", "journal", "flatly",
#'  "readable", "spacelab", "united", "cosmo", "lumen", "paper", "sandstone",
#'  "simplex", or "yeti"). 
#'  
#' @param progressive Display sub-topics progresively (i.e. wait until previous
#'   topics are either completed or skipped before displaying subsequent
#'   topics).
#' @param allow_skip Allow users to skip sub-topics (especially useful when
#'   \code{progressive} is \code{TRUE}).   
#'
#' @param ... Forward parameters to html_document
#'   
#' @export
tutorial <- function(fig_width = 6.5,
                     fig_height = 4,
                     fig_retina = 2,
                     fig_caption = TRUE,
                     progressive = FALSE,
                     allow_skip = FALSE,
                     dev = "png",
                     df_print = "paged",
                     smart = TRUE,
                     theme = "rstudio",
                     mathjax = "default",
                     extra_dependencies = NULL,
                     css = NULL,
                     includes = NULL,
                     md_extensions = NULL,
                     pandoc_args = NULL,
                     ...) {
  
  # base pandoc options 
  args <- c()
  
  # use section divs
  args <- c(args, "--section-divs")
  
  # template
  args <- c(args, "--template", pandoc_path_arg(
    system.file("rmarkdown/templates/tutorial/resources/tutorial-format.htm", 
                package = "learnr")
  ))
  
  # content includes
  args <- c(args, includes_to_pandoc_args(includes))
  
  # pagedtables
  if (identical(df_print, "paged")) {
    extra_dependencies <- append(extra_dependencies,
                                 list(html_dependency_pagedtable()))
  }
  
  # no pandoc highlighting
  args <- c(args, "--no-highlight")
  
  # add highlight.js html_dependency
  extra_dependencies <- append(extra_dependencies, list(html_dependency_highlightjs("textmate")))
    
  # additional css
  for (css_file in css)
    args <- c(args, "--css", pandoc_path_arg(css_file))
  
  # resolve theme (ammend base stylesheet for "rstudio" theme
  stylesheets <- "tutorial-format.css"
  if (identical(theme, "rstudio")) {
    stylesheets <- c(stylesheets, "rstudio-theme.css")
    theme <- "cerulean"
  }

  # additional tutorial-format js and css. note that we also include the 
  # tutorial_html_dependency() within our list of dependencies to ensure that
  # tutorial.js (and the API it provides) is always loaded prior to our
  # tutorial-format.js file.
  extra_dependencies <- append(extra_dependencies, list(
    tutorial_html_dependency(),
    tutorial_autocompletion_html_dependency(),
    tutorial_diagnostics_html_dependency(),
    htmltools::htmlDependency(
      name = "tutorial-format",
      version = utils::packageVersion("learnr"),
      src = system.file("rmarkdown/templates/tutorial/resources", package = "learnr"),
      script = "tutorial-format.js",
      stylesheet = stylesheets
    )
  ))
  
  # additional pandoc variables
  jsbool <- function(value) ifelse(value, "true", "false")
  args <- c(args, pandoc_variable_arg("progressive", jsbool(progressive)))
  args <- c(args, pandoc_variable_arg("allow-skip", jsbool(allow_skip)))
  
  # knitr and pandoc options
  knitr_options <- knitr_options_html(fig_width, fig_height, fig_retina, keep_md = FALSE , dev)
  pandoc_options <- pandoc_options(to = "html",
                                   from = from_rmarkdown(fig_caption, md_extensions),
                                   args = args)
  
  # set 1000 as the default maximum number of rows in paged tables
  knitr_options$opts_chunk$max.print <- 1000
  
  # create base document format using standard html_document
  base_format <- rmarkdown::html_document_base(
    smart = smart,
    theme = theme,
    lib_dir = NULL,
    mathjax = mathjax,
    pandoc_args = pandoc_args,
    template = "default",
    extra_dependencies = extra_dependencies,
    bootstrap_compatible = TRUE,
    ...
  )
  
  # return new output format
  rmarkdown::output_format(knitr = knitr_options,
                           pandoc = pandoc_options,
                           clean_supporting = FALSE,
                           df_print = df_print,
                           base_format = base_format)
}


# NOTE: get these three functions from rmarkdown once new version hits CRAN

# pandoc options for rmarkdown input
from_rmarkdown <- function(implicit_figures = TRUE, extensions = NULL) {
  
  # paste extensions together and remove whitespace
  extensions <- paste0(extensions, collapse = "")
  extensions <- gsub(" ", "", extensions)
  
  # exclude implicit figures unless the user has added them back
  if (!implicit_figures && !grepl("implicit_figures", extensions))
    extensions <- paste0("-implicit_figures", extensions)
  
  rmarkdown_format(extensions)
}


# create an html_dependency for pagedtable
html_dependency_pagedtable <- function() {
  htmlDependency(
    "pagedtable",
    version = "1.1",
    src = system.file("rmd/h/pagedtable-1.1", package = "rmarkdown"),
    script = "js/pagedtable.js",
    stylesheet = "css/pagedtable.css"
  )
}

html_dependency_highlightjs <- function(highlight) {
  htmlDependency(
    "highlightjs",
    version = "1.1",
    src = system.file("rmd/h/highlightjs-1.1", package = "rmarkdown"),
    script = "highlight.js",
    stylesheet = paste0(highlight, ".css")
  )
}

