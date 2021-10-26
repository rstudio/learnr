
# Given a line buffer, return a list of possible auto completions.
# If there is a valid label, then attache the server env to allow for local overrides of functions
auto_complete_r <- function(line, label, server_env) {

  # If the last line starts with a `#`, then it should be treated as a comment
  # No completions will be found if the last line is in a quote
  # If the line is within a quote then no completions will be found, so pre-emptively returning here is ok
  last_line <- tail(strsplit(line, "\n")[[1]], 1)
  if (grepl("^\\s*#", last_line)) {
    # If a comment is found, return `list()` to signify no completions are found
    # (Similar to the output of Map(list, list()))
    return(list())
  }

  # set completion settings
  options <- utils::rc.options()
  utils::rc.options(package.suffix = "::",
                    funarg.suffix = " = ",
                    function.suffix = "(")
  on.exit(do.call(utils::rc.options, as.list(options)), add = TRUE)

  # If and when exercises gain access to files, then we should evaluate this
  # code in the exercise dir with `quotes = TRUE` (and sanitize to keep
  # filename lookup local to exercise dir)
  settings <- utils::rc.settings()
  utils::rc.settings(ops = TRUE, ns = TRUE, args = TRUE, func = FALSE,
                      ipck = TRUE, S3 = TRUE, data = TRUE, help = TRUE,
                      argdb = TRUE, fuzzy = FALSE, files = FALSE, quotes = FALSE)
  on.exit(do.call(utils::rc.settings, as.list(settings)), add = TRUE)

  # temporarily attach global setup to search path
  # for R completion engine
  do.call("attach", list(server_env, name = "tutorial:server_env"))
  on.exit(detach("tutorial:server_env"), add = TRUE)

  # temporarily attach env to search path
  # for R completion engine
  if (nzchar(label) && is.environment(server_env[[label]])) {
    do.call("attach", list(server_env[[label]], name = "tutorial:question_env"))
    on.exit(detach("tutorial:question_env"), add = TRUE)
  }

  completions <- character()
  try(silent = TRUE, {
    utils <- asNamespace("utils")
    utils$.assignLinebuffer(line)
    utils$.assignEnd(nchar(line))
    utils$.guessTokenFromLine()
    utils$.completeToken()
    completions <- as.character(utils$.retrieveCompletions())
  })

  # detect functions
  splat <- strsplit(completions, ":{2,3}")
  fn <- vapply(splat, function(el) {
    n <- length(el)
    envir  <- if (n == 1) .GlobalEnv else asNamespace(el[[1]])
    symbol <- if (n == 2) el[[2]] else el[[1]]
    tryCatch(
      is.function(get(symbol, envir = envir)),
      error = function(e) FALSE
    )
  }, logical(1))

  # remove a leading '::', ':::' from autocompletion results, as
  # those won't be inserted as expected in Ace
  completions <- gsub("[^:]+:{2,3}(.)", "\\1", completions)
  completions <- completions[nzchar(completions)]

  # zip together
  result <- Map(list, completions, fn, USE.NAMES = FALSE)

  # return completions
  as.list(result)
}
