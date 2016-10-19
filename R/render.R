
renderFlexDashboard <- function(id, version = NULL) {

  tmp <- tempfile(fileext = ".Rmd")
  on.exit(unlink(tmp), add = TRUE)
  exportRmd(id, version, file = tmp)

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
