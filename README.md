---
output: github_document
---

### Overview

The **tutor** package makes it easy to turn any [R Markdown](http://rmarkdown.rstudio.com) document into an interactive tutorial. To create a tutorial, just use `library(tutor)` within your Rmd file to activate the package, then add the `exercise = TRUE` attribute to any R code chunk to make it interactive. 

For example, here's a very simple tutorial:

    ----
    title: "Hello, Tutor!"
    output: html_document
    runtime: shiny_prerendered
    ----
    
    ```{r setup, include=FALSE}
    library(tutor)
    ```
    
    The following code computes the answer to 1+1. Change it so it computes 2 + 2:
    
    ```{r, exercise=TRUE}
    1 + 1
    ```
    
This is what the running tutorial document looks like:

<img src="README_files/images/hello.png"/>
    
### Installation


```r
devtools::install_github("rstudio/tutor", auth_token = "33cdbf9d899fe6eff5022e67e21f08964f7c7b19")
```

### Examples



