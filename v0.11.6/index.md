# learnr

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

## Examples

Here are some examples of tutorials created with the **learnr** package.

[![Preview image of Setting Up
R](articles/images/tutorial-ex-setup-r.png)](https://learnr-examples.shinyapps.io/ex-setup-r/)

##### [Setting Up R](https://learnr-examples.shinyapps.io/ex-setup-r/)

A tutorial featuring videos and interactive questions to guide a new R
user through the installation and set up of everything they’ll need to
get started with R.

[Source](https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-setup-r/ex-setup-r.Rmd)

[![Preview image of Filtering
Observations](articles/images/tutorial-ex-data-filter.png)](https://learnr-examples.shinyapps.io/ex-data-filter/)

##### [Filtering Observations](https://learnr-examples.shinyapps.io/ex-data-filter/)

An example tutorial teaching a common `data` transformation: *filtering*
rows of a data frame with `dplyr::filter()`.

[Source](https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-data-filter/ex-data-filter.Rmd)

[![Preview image of Summarizing
Data](articles/images/tutorial-ex-data-summarise.png)](https://learnr-examples.shinyapps.io/ex-data-summarise)

##### [Summarizing Data](https://learnr-examples.shinyapps.io/ex-data-summarise)

An example tutorial where learners are introduced to
`dplyr::summarise()`. Along the way, learners also gain practice with
the pipe operator, `%>%`, and `dplyr::group_by()`.

[Source](https://github.com/rstudio/learnr/tree/main/inst/tutorials/ex-data-summarise/ex-data-manip-summarise.Rmd)

## Installation

Install the latest official learnr release from CRAN:

``` R
install.packages("learnr")
```

Or you can install the most recent version in-development from GitHub
with the [remotes package](https://remotes.r-lib.org):

``` R
# install.packages("remotes")
remotes::install_github("rstudio/learnr")
```

learnr works best with a recent [version of
RStudio](https://posit.co/download/rstudio-desktop/) (v1.0.136 or later)
which includes tools for easily running and previewing tutorials.

## Hello, Tutorial!

To create a tutorial, set `runtime: shiny_prerendered` in the YAML
frontmatter of your `.Rmd` file to turn your R Markdown document into an
[interactive app](https://rmarkdown.rstudio.com/lesson-14.html).

Then, call [`library(learnr)`](https://rstudio.github.io/learnr/) within
your Rmd file to activate tutorial mode, and use the `exercise = TRUE`
chunk option to turn code chunks into exercises. Users can edit and
execute the R code and see the results right within their browser.

For example, here’s a very simple tutorial:

```` markdown
---
title: "Hello, Tutorial!"
output: learnr::tutorial
runtime: shiny_prerendered
---

```{r setup, include=FALSE}
library(learnr)
```

This code computes the answer to one plus one,
change it so it computes two plus two:

```{r addition, exercise=TRUE}
1 + 1
```
````

This is what the running tutorial document looks like after the user has
entered their answer:

![](images/hello.png)
