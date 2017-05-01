```{r setup, include=FALSE}
library(learnr)
tutorial_options(exercise.eval = TRUE)
```

```{r filter, exercise=TRUE, exercise.eval=FALSE}
# Change the filter to select February rather than January
filter(nycflights, month == 1)
```