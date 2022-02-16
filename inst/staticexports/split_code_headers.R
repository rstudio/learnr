split_code_headers <- function(code, prefix = "section") {
  if (is.null(code)) {
    return(NULL)
  }

  code <- paste(code, collapse = "\n")
  code <- str_trim(code, character = "[\r\n]")
  code <- strsplit(code, "\n")[[1]]

  rgx_header <- "^(#+)([ -]*)(.+?)?\\s*----+$"
  headers <- regmatches(code, regexec(rgx_header, code, perl = TRUE))
  lines_headers <- which(vapply(headers, length, integer(1)) > 0)

  if (length(lines_headers) > 0 && max(lines_headers) == length(code)) {
    # nothing after last heading
    lines_headers <- lines_headers[-length(lines_headers)]
  }

  if (!length(lines_headers)) {
    return(list(paste(code, collapse = "\n")))
  }

  # header names are 3rd group, so 4th place in match since 1st is the whole match
  header_names <- vapply(headers[lines_headers], `[[`, character(1), 4)
  header_names <- str_trim(header_names)
  if (any(!nzchar(header_names))) {
    header_names[!nzchar(header_names)] <- sprintf(
      paste0(prefix, "%02d"),
      which(!nzchar(header_names))
    )
  }

  rgx_header_line <- gsub("[$^]", "(^|\n|$)", rgx_header)
  sections <- strsplit(paste(code, collapse = "\n"), rgx_header_line, perl = TRUE)[[1]]
  if (length(sections) > length(header_names)) {
    header_names <- c(paste0(prefix, "00"), header_names)
  }
  names(sections) <- header_names

  # trim leading/trailing new lines from code section
  sections <- str_trim(sections, character = "[\r\n]")
  # drop any sections that don't have anything in them
  sections <- sections[nzchar(str_trim(sections))]

  as.list(sections)
}
