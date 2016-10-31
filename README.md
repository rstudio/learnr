## Overview

The **tutor** package makes it easy to turn any [R Markdown](http://rmarkdown.rstudio.com) document into an interactive tutorial. To create a tutorial, just use `library(tutor)` within your Rmd file to activate tutorial mode, then add the `exercise = TRUE` attribute to any R code chunk to make it interactive. 

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
    
This is what the running tutorial document looks like after the user has entered their answer:

<kbd>
<img src="README_files/images/hello.png"  width="650" height="189" style="border: solid 1px #cccccc;"/>
</kbd>    
    
You can run a live version of this tutorial as follows:

```r
rmarkdown::run(system.file("examples/hello.Rmd", package = "tutor"))
```
    
    
We'll go thorugh this example in more detail below. First though let's cover how to install and get started with the **tutor** package.


## Getting Started

### Installation

You can install the development version of the **tutor** package from GitHub as follows:

```r
devtools::install_github("rstudio/tutor", auth_token = "33cdbf9d899fe6eff5022e67e21f08964f7c7b19")
```

You should also install the current [RStudio Preview Release](https://www.rstudio.com/products/rstudio/download/preview/) (v1.0.44 or higher) as it includes tools for easily running and previewing tutorials.

### Creating a Tutorial

A tutorial is just a standard R Markdown document that has three additional attributes:

1. It uses the `runtime: shiny_prerendered` directive in the YAML header.
2. It loads the **tutor** package.
3. It includes one or more code chunks with the `exercise=TRUE` attribute.

You can copy and paste the simple "Hello, Tutor!" example from above to get started creating your own tutorials.

Note that you aren't limited to the default `html_document` format when creating tutorials. Here's an example of embedding a tutorial within a `slidy_presentation`:

<kbd>
<img src="README_files/images/slidy.png" width="650" height="474" style="border: solid 1px #cccccc;"/>
</kbd>

You can run a live version of this tutorial as follows:

```r
rmarkdown::run(system.file("examples/slidy.Rmd", package = "tutor"))
```


### Running Tutorials

To run a tutorial you use the `rmarkdown::run` function (note this is done automatically when you use the **Run Document** command within RStudio):

```r
rmarkdown::run("tutorial.Rmd")
```

The `runtime: shiny_prerendered` element included in the YAML hints at the underlying implementation of tutorails: they are simply Shiny applications which use an R Markdown document as their user-interface rather than the traditional `ui.R` file.



## Tutorial Exercises


Standalone/Setup

Evaluation

Chunk Options


## Using Shiny

Shiny Prerendered




