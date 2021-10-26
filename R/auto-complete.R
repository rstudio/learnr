
# Given a line buffer, return a list of possible auto completions.
# If there is a valid label, then attach the server env to allow for local overrides of functions
auto_complete_r <- function(line, label = NULL, server_env = NULL) {

  # If the last line includes comments then we don't return any completions.
  # It's okay to consider only the last line for comments: Comment detection
  # takes into account quotes on the same line, but `quotes = FALSE` in the
  # completion settings below ensures completions aren't returned if the last
  # line is part of a multi-line quote.
  last_line <- tail(strsplit(line, "\n")[[1]], 1)
  if (detect_comment(last_line)) {
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
  if (isTRUE(nzchar(label)) && is.environment(server_env[[label]])) {
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

detect_comment <- function(line = "") {
  line <- strsplit(line, "")[[1]]
  quote_str <- ""
  in_quote <- FALSE
  in_escape <- FALSE
  for (char in line) {
    if (identical(char, "\\")) {
      in_escape <- TRUE
      next
    }
    if (char %in% c("'", '"')) {
      if (in_escape) {
        in_escape <- FALSE
      } else if (identical(quote_str, "")) {
        in_quote <- TRUE
        quote_str <- char
      } else if (identical(char, quote_str)) {
        in_quote <- FALSE
        quote_str <- ""
      } else {
        # ignore a quote within a quote
      }
      next
    }
    in_escape <- FALSE
    if (!identical(char, "#")) next
    if (in_quote) next
    return(TRUE)
  }

  FALSE
}
