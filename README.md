## Overview

The **tutor** package makes it easy to turn any [R Markdown](http://rmarkdown.rstudio.com) document into an interactive tutorial. To create a tutorial, just use `library(tutor)` within your Rmd file to activate tutorial mode, then use the `exercise = TRUE` attribute to turn code chunks into exercises. 

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
    
You can run a live version of this tutorial with:

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

You can run a live version of this tutorial with:

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

There are some special considerations for code chunks with `exercise=TRUE` which are covered in more depth below.

### Standalone Code

When a code chunk with `exercise=TRUE` is evaluated it's evaulated in a standalone environment (in other words, it doesn't have access to previous computations from within the document other than those provided in the `setup` chunk). This constraint is imposed so that users can execute exercises in any order (i.e. correct execution of one exercise never depends on completion of a prior exercise).

You can however arrange for per-exercise chunk setup code to be run to ensure that the environment is primed correctly. To do this give your exercise chunk a label (e.g. `exercise-1`) then add another chunk with the same label plus a `-setup` suffix (e.g. `exercise-1-setup`). For example, here we provide a setup chunk to ensure that a primed dataset is always available within an exercise's evaluation environment:


    ```{r exercise-1-setup}
    nycflights <- nycflights13::flights
    ```
    
    ```{r exercise-1, exercise=TRUE}
    # Change the filter to select February rather than January
    nycflights <- filter(nycflights, month == 1)
    ```

As mentioned above, you can also have global setup code that all chunks will get the benefit of by including a global `setup` chunk. For example, if there were multiple chunks that needed access to the original version of the flights datset you could do this:


    ```{r setup, include=FALSE}
    nycflights <- nycflights13::flights
    ```
    
    ```{r exercise-1, exercise=TRUE}
    # Change the filter to select February rather than January
    filter(nycflights, month == 1)
    ```

    ```{r exercise-1, exercise=TRUE}
    # Change the sort order to Ascending
    arrange(nycflights, desc(arr_delay))
    ```

### Evaluation



## Using Shiny

Shiny Prerendered

Dependent Files

## Deploying Tutorials






