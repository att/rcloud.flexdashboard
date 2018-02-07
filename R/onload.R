
caps <- NULL

.onLoad <- function(libname, pkgname) {
  
  if (requireNamespace("rcloud.shiny", quietly = TRUE)) {
    # We are loading this here to make sure that rcloud.shiny registers its ocaps
    # yet still keep rcloud.shiny as an optional pacakge.
    library("rcloud.shiny")
  }

  path <- system.file(
    package = "rcloud.flexdashboard",
    "javascript",
    "rcloud.flexdashboard.js"
  )

  caps <<- rcloud.install.js.module(
    "rcloud.flexdashboard",
    paste(readLines(path), collapse = '\n')
  )

  ocaps <- list(renderFlexDashboard = make_oc(renderFlexDashboard))

  if (!is.null(caps)) caps$init(ocaps)
}

.rcloud.export.ocaps <- function() { list() }

make_oc <- function(x) {
  do.call(base::`:::`, list("rcloud.support", "make.oc"))(x)
}
