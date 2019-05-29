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
#' @param progressive Display sub-topics progressively (i.e. wait until previous
#'   topics are either completed or skipped before displaying subsequent
#'   topics).
#' @param allow_skip Allow users to skip sub-topics (especially useful when
#'   \code{progressive} is \code{TRUE}).
#' @param highlight Syntax highlighting style. Supported styles include
#'        "default", "tango", "pygments", "kate", "monochrome",
#'        "espresso", "zenburn", "haddock", and "textmate". Pass ‘NULL’
#'        to prevent syntax highlighting.  Note, this value only pertains to standard rmarkdown code, not the Ace editor highlighting.
#' @param ace_theme Ace theme supplied to the ace code editor for all exercises.
#'        See \code{learnr:::ACE_THEMES} for a list of possible values.  Defaults to \code{"textmate"}.
#'
#' @param ... Forward parameters to html_document
#'
#' @export
#' @importFrom utils getFromNamespace
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
                     highlight = "textmate",
                     ace_theme = "textmate",
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
                                 list(rmarkdown::html_dependency_pagedtable()))
  }

  # highlight
  rmarkdown_pandoc_html_highlight_args <- getFromNamespace("pandoc_html_highlight_args", "rmarkdown")
  rmarkdown_is_highlightjs <- getFromNamespace("is_highlightjs", "rmarkdown")
  args <- c(args, rmarkdown_pandoc_html_highlight_args("default", highlight))
  # add highlight.js html_dependency if required
  if (rmarkdown_is_highlightjs(highlight)) {
    extra_dependencies <- append(extra_dependencies, list(rmarkdown::html_dependency_highlightjs(highlight)))
  }

  # ace theme
  if (!identical(ace_theme, "textmate")) {
    ace_theme <- match.arg(ace_theme, ACE_THEMES)
    args <- c(args, "--variable", paste0("ace-theme=", ace_theme))
  }


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
  pandoc_options <- pandoc_options(to = "html4",
    from = rmarkdown::from_rmarkdown(fig_caption, md_extensions),
    args = args,
    ext = ".html")

  # set 1000 as the default maximum number of rows in paged tables
  knitr_options$opts_chunk$max.print <- 1000

  # create base document format using standard html_document
  base_format <- rmarkdown::html_document(
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
