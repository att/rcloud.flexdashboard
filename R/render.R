
renderFlexDashboard <- function(id, version = NULL) {

  tmp <- tempfile(fileext = ".Rmd")
  on.exit(unlink(tmp), add = TRUE)
  exportRmd(id, version, file = tmp)

  tmp2 <- tempfile(fileext = ".html")
  on.exit(unlink(tmp2), add = TRUE)
  
  knitr:::knit_hooks$set(eval = progress_hook)
  on.exit(knitr:::knit_hooks$set(eval = NULL), add = TRUE)
  render(
    input = tmp,
    output_file = tmp2
  )

  contents <- paste(readLines(tmp2), collapse = "\n")

  caps$render(
    "#rcloud-flexdashboard", 
    gsub("\"", "&quot;", contents)
  )

  invisible()
}

progress <- function(status) {
  if(exists("caps")) {
    caps$progress(
      "#rcloud-flexdashboard-progress", 
      gsub("\"", "&quot;", paste0("Processing ", status))
    )
  } else {
    cat(gsub("\"", "&quot;", paste0("Processing ", status)))
  }
}

progress_hook <- function(before, options, envir) {
  progress(options$label)
  options
}

