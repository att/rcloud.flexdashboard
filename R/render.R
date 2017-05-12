
renderFlexDashboard <- function(id, version = NULL) {
#  tmp <- tempfile(fileext = ".Rmd") 
#  on.exit(unlink(tmp), add = TRUE)
  tmp_dir <- tempfile("flexdashboard")
  dir.create(tmp_dir)
#  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  tmp <- tempfile(tmpdir = tmp_dir, fileext = ".Rmd")
  exportRmd(id, version, file = tmp)
  exportCss(id, version, tmp_dir)
  
  tmp2 <- tempfile(fileext = ".html", tmpdir = tmp_dir)
#  tmp2 <- tempfile(fileext = ".html")
#  on.exit(unlink(tmp2), add = TRUE)
  knitr:::knit_hooks$set(eval = progress_hook)
  on.exit(knitr:::knit_hooks$set(eval = NULL), add = TRUE)
  render(
    input = tmp,
    output_file = tmp2
  )

  contents <- paste(readLines(tmp2), collapse = "\n")
  contents <- paste0(contents, "<!-- ", tmp_dir, "-->")
  caps$render(
    "#rcloud-flexdashboard", 
    gsub("\"", "&quot;", contents)
  )

  invisible()
}


exportCss <- function(notebook_id, version = NULL, tmp_dir) {
    res <- rcloud.support::rcloud.get.notebook(notebook_id, version)
    
    if (! res$ok) {
      return(NULL)
    }
    
    cells <- res$content$files
    cells <- cells[grep(".+\\.css$", names(cells))]
    lapply(cells, function(cell) {
      css_file <- file.path(tmp_dir, cell$filename)
      file.create(css_file);
      cat(format_cell(cell), file = css_file)
      return(css_file)
    });
}

format_cell <- function(cell) {
  paste0(cell$content, "\n")
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

