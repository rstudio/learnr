```{r filter, exercise=TRUE}
# Change the filter to select February rather than January
nycflights <- filter(nycflights, month == 1)
```

```{r filter-solution}
nycflights <- filter(nycflights, month == 2)
```