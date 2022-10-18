# learnr <a href='https://pkgs.rstudio.com/learnr'><img src='man/figures/logo.png' align="right" height="138" /></a>

<!-- badges: start -->

[![R build
status](https://github.com/rstudio/learnr/workflows/R-CMD-check/badge.svg)](https://github.com/rstudio/learnr)
[![CRAN
status](https://www.r-pkg.org/badges/version/learnr)](https://CRAN.R-project.org/package=learnr)
[![learnr downloads per
month](http://cranlogs.r-pkg.org/badges/learnr)](http://www.rpackages.io/package/learnr)
[![DOI](https://zenodo.org/badge/71377580.svg)](https://zenodo.org/badge/latestdoi/71377580)
<br /> [![GitHub
Discussions](https://img.shields.io/github/discussions/rstudio/learnr?logo=github&style=social)](https://github.com/rstudio/learnr/discussions)
[![RStudio
community](https://img.shields.io/badge/community-teaching-blue?style=social&logo=rstudio&logoColor=75AADB)](https://community.rstudio.com/c/teaching/13)
[![RStudio
community](https://img.shields.io/badge/community-learnr-blue?style=social&logo=rstudio&logoColor=75AADB)](https://community.rstudio.com/new-topic?title=&category_id=13&tags=learnr&body=%0A%0A%0A%20%20--------%0A%20%20%0A%20%20%3Csup%3EReferred%20here%20by%20%60learnr%60%27s%20GitHub%3C/sup%3E%0A&u=barret)
<!-- badges: end -->

The **learnr** package makes it easy to turn any [R
Markdown](http://rmarkdown.rstudio.com) document into an interactive
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

## Examples

Here are some examples of tutorials created with the **learnr** package.

<div class="row g-4 row-cols-1 row-cols-md-2 row-cols-lg-3">
<div class="col">
<div class="card h-100 shadow-sm">
<a href="https://learnr-examples.shinyapps.io/ex-setup-r/">
<img src="articles/images/tutorial-ex-setup-r.png" class="card-img-top" alt="Preview image of Setting Up R"/>
</a>
<div class="card-body">
<h5 class="card-title">
<a href="https://learnr-examples.shinyapps.io/ex-setup-r/">Setting Up R</a>
</h5>
<div class="card-text text-muted fs-6"><p>A tutorial featuring videos and interactive questions to guide a new R user through the installation and set up of everything they'll need to get started with R.</p>
</div>
</div>
<div class="card-footer text-end"><a href="https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-setup-r/ex-setup-r.Rmd">Source</a></div>
</div>
</div>
<div class="col">
<div class="card h-100 shadow-sm">
<a href="https://learnr-examples.shinyapps.io/ex-data-filter/">
<img src="articles/images/tutorial-ex-data-filter.png" class="card-img-top" alt="Preview image of Filtering Observations"/>
</a>
<div class="card-body">
<h5 class="card-title">
<a href="https://learnr-examples.shinyapps.io/ex-data-filter/">Filtering Observations</a>
</h5>
<div class="card-text text-muted fs-6"><p>An example tutorial teaching a common <code>data</code> transformation: <em>filtering</em> rows of a data frame with <code>dplyr::filter()</code>.</p>
</div>
</div>
<div class="card-footer text-end"><a href="https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-data-filter/ex-data-filter.Rmd">Source</a></div>
</div>
</div>
<div class="col">
<div class="card h-100 shadow-sm">
<a href="https://learnr-examples.shinyapps.io/ex-data-summarise">
<img src="articles/images/tutorial-ex-data-summarise.png" class="card-img-top" alt="Preview image of Summarizing Data"/>
</a>
<div class="card-body">
<h5 class="card-title">
<a href="https://learnr-examples.shinyapps.io/ex-data-summarise">Summarizing Data</a>
</h5>
<div class="card-text text-muted fs-6"><p>An example tutorial where learners are introduced to <code>dplyr::summarise()</code>. Along the way, learners also gain practice with the pipe operator, <code>%&gt;%</code>, and <code>dplyr::group_by()</code>.</p>
</div>
</div>
<div class="card-footer text-end"><a href="https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-data-summarise/ex-data-manip-summarise.Rmd">Source</a></div>
</div>
</div>
</div>

## Installation

Install the latest official learnr release from CRAN:

    install.packages("learnr")

Or you can install the most recent version in-development from GitHub
with the [remotes package](https://remotes.r-lib.org):

    # install.packages("remotes")
    remotes::install_github("rstudio/learnr")

learnr works best with a recent [version of
RStudio](https://www.rstudio.com/products/rstudio/download/) (v1.0.136
or later) which includes tools for easily running and previewing
tutorials.

## Hello, Tutorial!

To create a tutorial, set `runtime: shiny_prerendered` in the YAML
frontmatter of your `.Rmd` file to turn your R Markdown document into an
[interactive app](https://rmarkdown.rstudio.com/lesson-14.html).

Then, call `library(learnr)` within your Rmd file to activate tutorial
mode, and use the `exercise = TRUE` chunk option to turn code chunks
into exercises. Users can edit and execute the R code and see the
results right within their browser.

For example, here’s a very simple tutorial:

<div id="hello-learnr" class="sourceCode">
<pre class="markdown">
<code>---
title: "Hello, Tutorial!"
output: learnr::tutorial
runtime: shiny_prerendered
---

&#96;&#96;&#96;{r setup, include=FALSE}
library(learnr)
&#96;&#96;&#96;

This code computes the answer to one plus one,
change it so it computes two plus two:

&#96;&#96;&#96;{r addition, exercise=TRUE}
1 + 1
&#96;&#96;&#96;</code>
</pre>
</div>
<script type="text/javascript">loadSnippet('hello-learnr')</script>

This is what the running tutorial document looks like after the user has
entered their answer:

<img src="images/hello.png"  width="810" height="207" style="border: solid 1px #cccccc;"/>
