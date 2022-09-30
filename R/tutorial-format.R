#' Tutorial document format
#'
#' Long-form tutorial which includes narrative, figures, videos, exercises, and
#' questions.
#'
#' @examples
#' tutorial()
#'
#' @param theme Visual theme ("rstudio", default", "cerulean", "journal",
#'   "flatly", "readable", "spacelab", "united", "cosmo", "lumen", "paper",
#'   "sandstone", "simplex", or "yeti").
#' @param progressive Display sub-topics progressively (i.e. wait until previous
#'   topics are either completed or skipped before displaying subsequent
#'   topics).
#' @param allow_skip Allow users to skip sub-topics (especially useful when
#'   \code{progressive} is \code{TRUE}).
#' @param highlight Syntax highlighting style. Supported styles include
#'   "default", "tango", "pygments", "kate", "monochrome", "espresso",
#'   "zenburn", "haddock", and "textmate". Pass ‘NULL’ to prevent syntax
#'   highlighting.  Note, this value only pertains to standard rmarkdown code,
#'   not the Ace editor highlighting.
#' @param ace_theme Ace theme supplied to the ace code editor for all exercises.
#'   See \code{learnr:::ACE_THEMES} for a list of possible values.  Defaults to
#'   \code{"textmate"}.
#' @param smart Produce typographically correct output, converting straight
#'   quotes to curly quotes, \code{---} to em-dashes, \code{--} to en-dashes,
#'   and \code{...} to ellipses. Deprecated in \pkg{rmarkdown} v2.2.0.
#' @param ... Forward parameters to html_document
#' @param language Language or custom text of the UI elements. See
#'   `vignette("multilang", package = "learnr")` for more information about
#'   available options and formatting
#' @inheritParams rmarkdown::html_document
#' @inheritParams rmarkdown::html_document_base
#'
#' @return An [rmarkdown::output_format()] for \pkg{learnr} tutorials.
#'
#' @export
#' @importFrom utils getFromNamespace
tutorial <- function(
  fig_width = 6.5,
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
  language = "en",
  lib_dir = NULL,
  ...
) {

  if ("anchor_sections" %in% names(list(...))) {
    stop("learnr tutorials do not support the `anchor_sections` option.")
  }

  # base pandoc options
  args <- c()

  # use section divs
  args <- c(args, "--section-divs")

  # footnotes are scoped to the block
  args <- c(args, "--reference-location=section")

  # template
  args <- c(args, "--template", rmarkdown::pandoc_path_arg(
    system.file("rmarkdown/templates/tutorial/resources/tutorial-format.htm",
                package = "learnr")
  ))

  # content includes
  args <- c(args, rmarkdown::includes_to_pandoc_args(includes))

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
    tutorial_i18n_html_dependency(language),
    htmltools::htmlDependency(
      name = "tutorial-format",
      version = utils::packageVersion("learnr"),
      src = system.file("rmarkdown/templates/tutorial/resources", package = "learnr"),
      script = "tutorial-format.js",
      stylesheet = stylesheets
    )
  ))

  # additional pandoc variables specific to learnr
  jsbool <- function(value) ifelse(value, "true", "false")
  args <- c(
    args,
    rmarkdown::pandoc_variable_arg("progressive", jsbool(progressive)),
    rmarkdown::pandoc_variable_arg("allow-skip", jsbool(allow_skip)),
    rmarkdown::pandoc_variable_arg("learnr-version", utils::packageVersion("learnr"))
  )

  # knitr and pandoc options
  knitr_options <- rmarkdown::knitr_options_html(fig_width, fig_height, fig_retina, keep_md = FALSE , dev)
  pandoc_options <- rmarkdown::pandoc_options(to = "html4",
    from = rmarkdown::from_rmarkdown(fig_caption, md_extensions),
    args = args,
    ext = ".html")

  tutorial_opts <- tutorial_knitr_options()
  knitr_options <- utils::modifyList(knitr_options, tutorial_opts)

  # set 1000 as the default maximum number of rows in paged tables
  knitr_options$opts_chunk$max.print <- 1000

  # create base document format using standard html_document
  base_format <- rmarkdown::html_document(
    smart = smart,
    theme = theme,
    mathjax = mathjax,
    pandoc_args = pandoc_args,
    template = "default",
    extra_dependencies = extra_dependencies,
    bootstrap_compatible = TRUE,
    anchor_sections = FALSE,
    css = css,
    ...
  )

  # return new output format
  rmarkdown::output_format(knitr = knitr_options,
                           pandoc = pandoc_options,
                           clean_supporting = FALSE,
                           df_print = df_print,
                           base_format = base_format)
}
