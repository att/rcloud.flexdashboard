
renderFlexDashboard <- function(id, version = NULL) {

  res <- rcloud.get.notebook(id, version)

  if (! res$ok) return(NULL)

  cells <- res$content$files
  cells <- cells[grep("^part", names(cells))]
  if (!length(names(cells))) return(NULL)

  cnums <- suppressWarnings(as.integer(
    gsub("^\\D+(\\d+)\\..*", "\\1", names(cells))
  ))
  cells <- cells[match(sort.int(cnums), cnums)]

  tmp <- tempfile(fileext = ".Rmd")
  on.exit(unlink(tmp), add = TRUE)
  cat("", file = tmp)

  for (cell in cells) {
    if (grepl("^part.*\\.R$", cell$filename)) {
      cat("\n```{r}\n", cell$content, "\n```\n", sep = "", file = tmp, append = TRUE)

    } else if (grepl("^part.*\\.md$", cell$filename)) {
      cat("\n", cell$content, "\n", sep = "", file = tmp, append = TRUE)
    }
  }

  tmp2 <- tempfile(fileext = ".html")
  on.exit(unlink(tmp2), add = TRUE)
  render(
    input = tmp,
    output_file = tmp2
  )

  contents <- paste(readLines(tmp2), collapse = "\n")

  caps$render(
    "#rcloud-flexdashboard",
    paste0(
      "<iframe frameBorder=\"0\" width=\"100%\" height=\"100%\" srcdoc=\"",
      gsub("\"", "&quot;", contents),
      "\"></iframe>"
    )
  )

  invisible()
}
