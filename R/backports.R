# q was added to dQuote() in 3.6.0
dQuote <- function(x, q = TRUE) {
  opts <- options(useFancyQuotes = isTRUE(q))
  on.exit(options(opts))
  base::dQuote(x)
}
