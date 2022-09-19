# render_exercise() user code exercise.Rmd snapshot

    Code
      writeLines(render_exercise_rmd_user(ex))
    Output
      ```{r learnr-setup, include=FALSE}
      # hack the pager function so that we can print help with custom pager function
      # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
      options(pager = function(files, header, title, delete.file) {
        cat(do.call('c', lapply(files, readLines)), sep = '\n')
      })
      knitr::opts_chunk$set(echo = FALSE, comment = NA, error = FALSE)
      ```
      
      ```{r "ex", exercise=TRUE}
      USER_CODE <- "PASS"
      ```

---

    Code
      writeLines(render_exercise_rmd_user(ex_sql))
    Output
      ```{r learnr-setup, include=FALSE}
      # hack the pager function so that we can print help with custom pager function
      # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
      options(pager = function(files, header, title, delete.file) {
        cat(do.call('c', lapply(files, readLines)), sep = '\n')
      })
      knitr::opts_chunk$set(echo = FALSE, comment = NA, error = FALSE)
      ```
      
      ```{sql "ex", exercise=TRUE}
      SELECT * FROM USER
      ```
      
      ```{r eval=exists("___sql_result")}
      get("___sql_result")
      ```

# SQL exercises - without explicit `output.var`

    Code
      writeLines(render_exercise_rmd_user(render_exercise_prepare(ex_sql_engine)))
    Output
      ```{r learnr-setup, include=FALSE}
      # hack the pager function so that we can print help with custom pager function
      # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
      options(pager = function(files, header, title, delete.file) {
        cat(do.call('c', lapply(files, readLines)), sep = '\n')
      })
      knitr::opts_chunk$set(echo = FALSE, comment = NA, error = FALSE)
      ```
      
      ```{sql "db", connection=db_con, output.var="___sql_result"}
      SELECT * FROM mtcars
      ```
      
      ```{r eval=exists("___sql_result")}
      get("___sql_result")
      ```

# SQL exercises - with explicit `output.var`

    Code
      writeLines(render_exercise_rmd_user(render_exercise_prepare(ex_sql_engine)))
    Output
      ```{r learnr-setup, include=FALSE}
      # hack the pager function so that we can print help with custom pager function
      # http://stackoverflow.com/questions/24146843/including-r-help-in-knitr-output
      options(pager = function(files, header, title, delete.file) {
        cat(do.call('c', lapply(files, readLines)), sep = '\n')
      })
      knitr::opts_chunk$set(echo = FALSE, comment = NA, error = FALSE)
      ```
      
      ```{sql "db", connection=db_con, output.var="___sql_result"}
      SELECT * FROM mtcars
      ```
      
      ```{r eval=exists("___sql_result")}
      get("___sql_result")
      ```

# exercise print method

    Code
      example_exercise
    Output
      ```{r "ex", exercise=TRUE}
      1 + 1
      ```
      
      ```{r "ex-solution"}
      2 + 2
      ```
      
      ```{r "ex-code-check"}
      3 + 3
      ```
      
      ```{r "ex-check"}
      5 + 5
      ```
      
      ```{r "ex-error-check"}
      4 + 4
      ```

