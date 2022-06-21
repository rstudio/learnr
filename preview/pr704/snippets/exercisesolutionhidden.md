```{r filter, exercise=TRUE}
# filter the flights table to include only United and American flights
flights
```

```{r filter-hint-1}
filter(flights, ...)
```

```{r filter-hint-2}
filter(flights, UniqueCarrier=="AA")
```

```{r filter-solution, exercise.reveal_solution = FALSE}
filter(flights, UniqueCarrier=="AA" | UniqueCarrier=="UA")
```