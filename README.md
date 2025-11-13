# learnr <a href='https://rstudio.github.io/learnr/'><img src='man/figures/logo.png' align="right" height="138" /></a>

<!-- badges: start -->

[![R build
status](https://github.com/rstudio/learnr/workflows/R-CMD-check/badge.svg)](https://github.com/rstudio/learnr)
[![CRAN
status](https://www.r-pkg.org/badges/version/learnr)](https://CRAN.R-project.org/package=learnr)
[![DOI](https://zenodo.org/badge/71377580.svg)](https://zenodo.org/badge/latestdoi/71377580)
<br /> [![GitHub
Discussions](https://img.shields.io/github/discussions/rstudio/learnr?logo=github&style=social)](https://github.com/rstudio/learnr/discussions)
[![Posit
community](https://img.shields.io/badge/community-learnr-blue?style=social&logo=posit&logoColor=447099)](https://forum.posit.co/latest?tags=learnr)
<!-- badges: end -->

The **learnr** package makes it easy to turn any [R
Markdown](https://rmarkdown.rstudio.com/) document into an interactive
tutorial. Tutorials consist of content along with interactive components
for checking and reinforcing understanding. Tutorials can include any or
all of the following:

1.  Narrative, figures, illustrations, and equations.

2.  Code exercises (R code chunks that users can edit and execute
    directly).

3.  Quiz questions.

4.  Videos (supported services include YouTube and Vimeo).

5.  Interactive Shiny components.

Tutorials automatically preserve work done within them, so if a user
works on a few exercises or questions and returns to the tutorial later
they can pick up right where they left off.

Learn more about the **learnr** package and try example tutorials online
at <https://rstudio.github.io/learnr/>.

## Installation

Install the latest official learnr release from CRAN:

    install.packages("learnr")

Or you can install the most recent version in-development from GitHub
with the [remotes package](https://remotes.r-lib.org):

    # install.packages("remotes")
    remotes::install_github("rstudio/learnr")

learnr works best with a recent [version of
RStudio](https://posit.co/download/rstudio-desktop/) (v1.0.136 or later)
which includes tools for easily running and previewing tutorials.
