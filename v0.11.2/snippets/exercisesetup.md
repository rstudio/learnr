```{r setup, include=FALSE}
nycflights <- nycflights13::flights
```

```{r filter, exercise=TRUE}
# Change the filter to select February rather than January
filter(nycflights, month == 1)
```

```{r arrange, exercise=TRUE}
# Change the sort order to Ascending
arrange(nycflights, desc(arr_delay))
```