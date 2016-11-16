---
title: "Deployment"
---

Tutorials can be deployed all of the same ways that Shiny applications can, including running locally on an end-user's machine or running on a Shiny Server or hosting service like shinyapps.io. 

## Local Deployment

For local deployment, you should consider bundling the tutorial into an R package and providing a high level function to run it. For example, the following functions provide wrappers around the "hello.Rmd" and "slidy.Rmd" tutorials we ran earlier:

```r
hello_tutorial <- function() {
  rmarkdown::run(system.file("examples/hello.Rmd", package = "tutor"))
}

slidy_tutorial <- function() {
  rmarkdown::run(system.file("examples/slidy.Rmd", package = "tutor"))
}
```

## Server Deployment

You can also deploy tutorials on a server as you'd deploy any other Shiny application (the [Deployment](http://rmarkdown.rstudio.com/authoring_shiny_prerendered.html#deployment) section of the `runtime: shiny_prerendered` documentation has additional details on how to do this).

Note however that there is one important difference between tutorials and most other Shiny applications you deploy: with tutorials end users are providing R code to be executed on the server. This creates some special considerations around resources, concurrent usage, and security which are discussed below. 

As a result of these considerations local deployment of tutorials is the recommended approach unless you feel comfortable that you've accounted for these concerns. Note that if you deploy tutorials to end users running RStudio Server then you can get the best of both worlds (centralized deployment with a local execution context that is segregated from other users of the same server).

## Resource Usage

Since users can execute arbitrary R code within a tutorial, this code can also consume arbitrary resources and time! (e.g. users could create an infinite loop or allocate all available memory on the machine).

To apply resource limits, you can run tutorials within system imposed resource managers (e.g. ulimit or cgroups) or alternatively use a containerization technology like LXC or Docker. You can also apply resources limits using the [RAppArmor](https://cran.r-project.org/web/packages/RAppArmor/index.html) package, which is described below in the [Security](#Security) section.

To limit the time taken for the execution of exercises you can use the `exercise.timelimit` option described in the [Exercise Timeouts](#exercise-timeouts) section above.

## Concurrent Users

If you have multiple users accessing a tutorial at the same time their R code will by default be executed within a single R process. This means that if exercises take a long time to complete and many users are submitting them at once there could be a long wait for some users. 

The `exercise.timelimit` option described above is a way to prevent this problem in some cases, but in other cases you may need to run your tutorial using multiple R processes. This is possible using [shinyapps.io](http://docs.rstudio.com/shinyapps.io/applications.html#ApplicationInstances), [Shiny Server Pro](http://docs.rstudio.com/shiny-server/#utilization-scheduler), and [RStudio Connect](http://docs.rstudio.com/connect/admin/appendix-configuration.html#appendix-configuration-scheduler) (see the linked documentation for the various products for additional details).

## Security

Since tutorials enable end users to submit R code for execution on the server, you need to architect your deployment of tutorials so that code is placed in an appropriate sandbox. There are a variety of ways to accomplish this including placing the entire Shiny Server in a container or Linux namespace that limits it's access to the filesystem and/or other system resources.

The **tutor** package can also have it's exercise evaluation function replaced with one based on the [RAppArmor](https://cran.r-project.org/web/packages/RAppArmor/index.html) package. Using this method you can apply time limits, resource limits, and filesystem limits. Here are the steps required to use RAppArmor:

1. Install and configure the **RAppArmor** package as described here: https://github.com/jeroenooms/RAppArmor#readme

2. Add the following line to the `/etc/apparmor.d/rapparmor.d/r-user` profile (this is required so that the default AppArmor profile also support calling the pandoc markdown renderer):

    ```bash
    /usr/lib/rstudio/bin/pandoc/* rix,
    ```

3. Define an evaluator function that uses `RAppArmor::eval.secure` and set it as the `tutor.exercise.evaluator` global options (you'd do this in e.g. the `Rprofile.site`):

    ```r
    # exercise evaluation function
    apparmor_evaluate_exercise <- function(expr, timelimit) {
      RAppArmor::eval.secure(expr, 
                             timeout = timelimit, 
                             profile="r-user",
                             RLIMIT_NPROC = 1000,
                             RLIMIT_AS = 1024*1024*1024) 
    }
    
    # install as exercise evaluator
    options(tutor.exercise.evaluator = apparmor_evaluate_exercise)
    ```


