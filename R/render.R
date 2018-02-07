
renderFlexDashboard <- function(id, version = NULL) {
  if(rcloud.session.info()$user == "" && !rcloud.is.notebook.published(id))
    stop("Notebook \"", URLencode(id, TRUE), "\" does not exist or has not been published")
  tmp_dir <- tempfile("flexdashboard")
  dir.create(tmp_dir)
  
  tmpRmd <- tempfile(tmpdir = tmp_dir, fileext = ".Rmd")
  exportRmd(id, version, file = tmpRmd)
  exportCss(id, version, tmp_dir)
  
  front_matter <- rmarkdown:::yaml_front_matter(tmpRmd)
  
  
  knitr:::knit_hooks$set(eval = progress_hook)
  on.exit(knitr:::knit_hooks$set(eval = NULL), add = TRUE)
  
  if('runtime' %in% names(front_matter) && front_matter$runtime %in% c('shiny', 'shiny_prerendered')) {
    addSessionCloseCallback(rmDirCallback(tmp_dir))
    if (requireNamespace("rcloud.shiny", quietly = TRUE)) {
      rmarkdown.run.override(tmpRmd, 
                             auto_reload = FALSE,
                             renderer = function(url) {   
                               caps$renderShinyUrl("#rcloud-flexdashboard", url)
                               rcw.result(run = function(...) { }, body = "")
                             })
    } else {
      stop("flexdashboards that use shiny runtime require rcloud.shiny package, please install it and try again.")
    }
  } else {
    tmpHtml <- tempfile(fileext = ".html", tmpdir = tmp_dir)
    on.exit(unlink(tmp_dir), add = TRUE)
    render(
      input = tmpRmd, 
      output_file = basename(tmpHtml)
    )
    contents <- paste(readLines(tmpHtml), collapse = "\n")
    caps$render(
      "#rcloud-flexdashboard", 
      gsub("\"", "&quot;", contents)
    )
  }

  invisible()
}

exportCss <- function(notebook_id, version = NULL, tmp_dir) {
    res <- rcloud.support::rcloud.get.notebook(notebook_id, version)
    
    if (!res$ok) {
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

rmDirCallback <- function(dir.path) {
  directory <- dir.path
  function() {
    if(!is.null(directory) && file.exists(directory)) {
      unlink(directory, recursive = TRUE)
    }
  }
}

addSessionCloseCallback <- function(FUN) {
  f <- .GlobalEnv$.Rserve.done
  .GlobalEnv$.Rserve.done <- function(...) {
    FUN()
    if(is.function(f)) {
      f(...)
    }
  }
  
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
