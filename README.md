
## learnr: Interactive tutorials for R

<!-- badges: start -->
[![R build status](https://github.com/rstudio/learnr/workflows/R-CMD-check/badge.svg)](https://github.com/rstudio/learnr)
[![Tutorial deploy status](https://github.com/rstudio/learnr/workflows/deploy/badge.svg)](https://github.com/rstudio/shinycoreci/actions?query=workflow%3ADeploy)
[![CRAN status](https://www.r-pkg.org/badges/version/learnr)](https://CRAN.R-project.org/package=learnr)
[![learnr downloads per month](http://cranlogs.r-pkg.org/badges/learnr)](http://www.rpackages.io/package/learnr)
[![DOI](https://zenodo.org/badge/71377580.svg)](https://zenodo.org/badge/latestdoi/71377580)
<br /> [![RStudio community](https://img.shields.io/badge/community-teaching-blue?style=social&logo=rstudio&logoColor=75AADB)](https://community.rstudio.com/c/teaching)
[![RStudio community](https://img.shields.io/badge/community-learnr-blue?style=social&logo=rstudio&logoColor=75AADB)](https://community.rstudio.com/new-topic?title=&category_id=13&tags=learnr&body=%0A%0A%0A%20%20--------%0A%20%20%0A%20%20%3Csup%3EReferred%20here%20by%20%60learnr%60%27s%20GitHub%3C/sup%3E%0A&u=barret)
<!-- badges: end -->

The **learnr** package makes it easy to turn any [R
Markdown](http://rmarkdown.rstudio.com) document into an interactive
tutorial. Tutorials consist of content along with interactive components
for checking and reinforcing understanding. Tutorials can include any or
all of the following:

1.  Narrative, figures, illustrations, and equations.

2.  Videos (supported services include YouTube and Vimeo).

3.  Code exercises (R code chunks that users can edit and execute
    directly).

4.  Quiz questions.

5.  Interactive Shiny components.

You can find documentation on using the **learnr** package here:
<https://rstudio.github.com/learnr/>

## FAQ

#### Error: Deployment Dependencies Not Found

If your tutorial contains broken code within exercises for users to fix, the CRAN version of [`packrat`](https://github.com/rstudio/packrat/) will not find all of your dependencies to install when the tutorial is deployed. To deploy tutorials containing broken exercise code, install the development version of `packrat`. This version of `packrat` is able to find dependencies per R chunk, allowing for *broken* R chunks within the tutorial file.

``` r
devtools::install_github("rstudio/packrat")
```

#### IE / Edge Support

`learnr` does not actively support IE11 and Edge.

- [IE11 not receiving major updates](https://support.microsoft.com/en-us/help/17454/lifecycle-faq-internet-explorer), so I am not pursuing support for IE11.
- [Edge is adopting chromium](https://blogs.windows.com/windowsexperience/2018/12/06/microsoft-edge-making-the-web-better-through-more-open-source-collaboration/). Once updated, Edge *should* work out of the box with many more R packages (including `learnr`) and websites.
