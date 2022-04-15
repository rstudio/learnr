
#' An Exercise Checker for Debugging
#'
#' An exercise checker for debugging that renders all of the expected arguments
#' of the `exercise.checker` option into HTML. Additionally, this function is
#' used in testing  of `evaluate_exercise()`.
#'
#' @param label Exercise label
#' @param user_code Submitted user code
#' @param solution_code The code in the `*-solution` chunk
#' @param check_code The checking code that originates from the `*-check` chunk,
#'   the `*-code-check` chunk, or the `*-error-check` chunk.
#' @param envir_prep,envir_result The environment before running user code
#'   (`envir_prep`) and the environment just after running the user's code
#'   (`envir_result`).
#' @param evaluate_result The return value from `evaluate::evaluate()`, called
#'   on `user_code`
#' @param last_value The last value after evaluating `user_code`
#' @param engine The engine of the exercise chunk
#' @param ... Not used (future compatibility)
#'
#' @keywords internal
debug_exercise_checker <- function(
    label,
    user_code,
    solution_code,
    check_code,
    envir_result,
    evaluate_result,
    envir_prep,
    last_value,
    engine,
    ...
) {
  # Use I() around check_code to indicate that we want to evaluate the check code
  checker_result <- if (is_AsIs(check_code)) {
    local(eval(parse(text = check_code)))
  }

  tags <- htmltools::tags
  collapse <- function(...) paste(..., collapse = "\n")

  str_chr <- function(x) {
    utils::capture.output(utils::str(x))
  }

  str_env <- function(env) {
    if (is.null(env)) {
      return("NO ENVIRONMENT")
    }
    vars <- ls(env)
    names(vars) <- vars
    x <- str_chr(lapply(vars, function(v) get(v, env)))
    x[-1]
  }

  code_block <- function(value, engine = "r") {
    tags$pre(
      class = engine,
      tags$code(collapse(value), .noWS = "inside"),
      .noWS = "inside"
    )
  }

  message <- htmltools::tagList(
    tags$p(
      tags$strong("Exercise label:"),
      tags$code(label),
      tags$br(),
      tags$strong("Engine:"),
      tags$code(engine)
    ),
    tags$p(
      "last_value",
      code_block(last_value)
    ),
    tags$details(
      tags$summary("envir_prep"),
      code_block(str_env(envir_prep))
    ),
    tags$details(
      tags$summary("envir_result"),
      code_block(str_env(envir_result))
    ),
    tags$details(
      tags$summary("user_code"),
      code_block(user_code, engine)
    ),
    tags$details(
      tags$summary("solution_code"),
      code_block(solution_code)
    ),
    tags$details(
      tags$summary("check_code"),
      code_block(check_code)
    ),
    tags$details(
      tags$summary("evaluate_result"),
      code_block(str_chr(evaluate_result))
    )
  )

  list(
    message = message,
    correct = logical(),
    type = "custom",
    location = "replace",
    checker_result = checker_result,
    checker_args = list(
      label           = label,
      user_code       = user_code,
      solution_code   = solution_code,
      check_code      = check_code,
      envir_result    = envir_result,
      evaluate_result = evaluate_result,
      envir_prep      = envir_prep,
      last_value      = last_value,
      engine          = engine,
      "..."           = list(...)
    )
  )
}
