```{r math, echo=FALSE}
x <- 42
question(sprintf("Suppose $x = %s$. Choose the correct statement:", x),
  answer(sprintf("$\\sqrt{x} = %d$", x + 1)),
  answer(sprintf("$x ^ 2 = %d$", x^2), correct = TRUE),
  answer("$\\sin x = 1$")
)
```