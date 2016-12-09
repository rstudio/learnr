

#' Tutorial document format
#' 
#' Long-form tutorial which includes narrative, figures, videos, exercises, and quesitons.
#' 
#' @inheritParams rmarkdown::html_document
#' 
#' @param ... Forward parameters to html_document
#' 
#' @export
tutorial <- function(toc = TRUE,
                     toc_depth = 3,
                     toc_float = TRUE,
                     fig_width = 6.5,
                     fig_height = 4,
                     fig_retina = 2,
                     fig_caption = TRUE,
                     dev = "png",
                     df_print = "paged",
                     smart = TRUE,
                     theme = "cerulean",
                     highlight = "textmate",
                     mathjax = "default",
                     extra_dependencies = NULL,
                     css = NULL,
                     includes = NULL,
                     md_extensions = NULL,
                     pandoc_args = NULL,
                     ...) {
  
  # create base document format using standard html_document
  base_format <- rmarkdown::html_document(
    toc = toc,
    toc_depth = toc_depth,
    toc_float = toc_float,
    fig_width = fig_width,
    fig_height = fig_height,
    fig_retina = fig_retina,
    fig_caption = fig_caption,
    dev = dev,
    df_print = df_print,
    code_folding = "none",
    code_download = FALSE,
    smart = smart,
    theme = theme,
    highlight = highlight,
    mathjax = mathjax,
    extra_dependencies = extra_dependencies,
    css = css,
    includes = includes,
    keep_md = FALSE,
    lib_dir = NULL,
    md_extensions = md_extensions,
    pandoc_args = pandoc_args,
    ...
  )
  
  # return new output format
  rmarkdown::output_format(knitr = NULL,
                           pandoc = NULL,
                           base_format = base_format)
}