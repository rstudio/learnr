```{r setup, include=FALSE}
library(learnr)
gradethis::gradethis_setup()
```

* Submit `1+1` to receive a correct grade.

```{r exercise1, exercise = TRUE}

```
 
```{r exercise1-check}
grade_result(
  pass_if(~identical(.result, 2))
)
```
