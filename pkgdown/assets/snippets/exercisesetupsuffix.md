```{r filter-setup}
nycflights <- nycflights13::flights
```

```{r filter, exercise=TRUE}
# Change the filter to select February rather than January
nycflights <- filter(nycflights, month == 1)
```