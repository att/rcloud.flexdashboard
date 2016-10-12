
.onLoad <- function(libname, pkgname) {

  path <- system.file(
    package = "rcloud.flexdashboard",
    "javascript",
    "rcloud.flexdashboard.js"
  )

  caps <- rcloud.install.js.module(
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
