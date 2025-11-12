# Mock a learnr interactive exercise

Creates an interactive exercise object that can be used in tests without
having to create a learnr tutorial.

## Usage

``` r
mock_exercise(
  user_code = "1 + 1",
  label = "ex",
  chunks = list(),
  engine = "r",
  global_setup = NULL,
  setup_label = NULL,
  solution_code = NULL,
  code_check = NULL,
  error_check = NULL,
  check = NULL,
  tests = NULL,
  exercise.checker = NULL,
  exercise.error.check.code = NULL,
  exercise.df_print = "default",
  exercise.warn_invisible = TRUE,
  exercise.timelimit = 10,
  fig.height = 4,
  fig.width = 6.5,
  fig.retina = 2,
  version = current_exercise_version,
  ...
)

mock_chunk(label, code, exercise = FALSE, engine = "r", ...)
```

## Arguments

- user_code, solution_code, global_setup:

  The user, solution, and global setup code, as strings.

- label:

  The label of the exercise.

- chunks:

  A list of chunks to use for the exercise. Use `mock_chunk()` to create
  chunks.

- engine:

  The knitr language engine used by the exercise, equivalent to the
  engine used for the chunk with `exercise = TRUE` in a tutorial.

- setup_label:

  The label of the chunk that contains the setup code. The chunk itself
  should be among the list of chunks provided to the `chunks` argument
  and the label of the setup chunk needs to match the label provided to
  `setup_label`.

- check, code_check, error_check:

  The checking code, as a string, that would typically be provided in
  the `-check`, `-code-check` and `-error-check` chunks in a learnr
  tutorial.

- exercise.checker:

  The exercise checker function, as a string. By default, a debug
  exercise checker is set but will only be used if any of `check`,
  `code_check` or `error_check` are provided.

- exercise.error.check.code:

  The default code used for `error_check` and applied only when `check`
  or `code_check` are provided and the user's code throws an error.

- exercise.df_print, exercise.warn_invisible, exercise.timelimit,
  fig.height, fig.width, fig.retina:

  Common exercise chunk options.

- version:

  The exercise version to emulate, by default `mock_exercise()` will
  return an exercise that matches the current exercise version.

- ...:

  Additional chunk options as if there were included in the exercise
  chunk.

- code:

  In `mock_chunk()`, the code in the mocked chunk.

- exercise:

  In `mock_chunk()`, is this chunk the exercise chunk? If so,
  `mock_exercise()` will not create the exercise chunk for you.

## Value

An exercise object.

## Functions

- `mock_exercise()`: Create a learnr exercise object

- `mock_chunk()`: Create a mock exercise-supporting chunk

## Examples

``` r
mock_exercise(
  user_code = "1 + 1",
  solution_code = "2 + 2",
  label = "two-plus-two"
)
#> ```{r "two-plus-two", exercise=TRUE}
#> 1 + 1
#> ```
#> 
#> ```{r "two-plus-two-solution"}
#> 2 + 2
#> ```

# Global Setup
mock_exercise(
  user_code = 'storms %>% filter(name = "Roxanne")',
  solution_code = 'storms %>% filter(name == "Roxanne")',
  global_setup = 'library(learnr)\nlibrary(dplyr)',
  label = "filter-storms"
)
#> ```{r "filter-storms", exercise=TRUE}
#> storms %>% filter(name = "Roxanne")
#> ```
#> 
#> ```{r "filter-storms-solution"}
#> storms %>% filter(name == "Roxanne")
#> ```

# Chained setup chunks
mock_exercise(
  user_code = "roxanne",
  solution_code = "roxanne %>%
  group_by(year, month, day) %>%
  summarize(wind = mean(wind))",
  chunks = list(
    mock_chunk(
      label = "prep-roxanne",
      code = 'roxanne <- storms %>% filter(name == "Roxanne")'
    )
  ),
  setup_label = "prep-roxanne",
  global_setup = "library(learnr)\nlibrary(dplyr)"
)
#> ```{r "prep-roxanne"}
#> roxanne <- storms %>% filter(name == "Roxanne")
#> ```
#> 
#> ```{r "ex", exercise.setup="prep-roxanne", exercise=TRUE}
#> roxanne
#> ```
#> 
#> ```{r "ex-solution"}
#> roxanne %>%
#>   group_by(year, month, day) %>%
#>   summarize(wind = mean(wind))
#> ```
```
