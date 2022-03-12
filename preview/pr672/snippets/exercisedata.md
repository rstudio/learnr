```{r setup}
library(tidyverse)

flights_jan <- 
  nycflights13::flights %>% 
  filter(month == 2)
  
dir.create("data",  showWarnings = FALSE)
write_csv(flights_jan, "data/flights_jan.csv")
```

```{r read-flights, exercise=TRUE}
read_csv("data/flights_jan.csv")
```
