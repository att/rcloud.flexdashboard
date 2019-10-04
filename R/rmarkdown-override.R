# the source in this file is licensed under GPL-3, copyright RStudio and contributors; see
# https://github.com/rstudio/rmarkdown/blob/master/DESCRIPTION for details.

# Based on rmarkdown:::run
# Main changes:
# * Don't launch browser
# * Integrate with rcloud.shiny instead of invoking shiny functions.
rmarkdown.run.override <- function(file, dir = dirname(file), auto_reload = TRUE, shiny_args = NULL, render_args = NULL, renderer = NULL) {
  
  default_file <- basename(file)
  target_file <- file
  dir <- rmarkdown:::normalize_path(dir)
  encoding <- if (is.null(render_args$encoding)) 
    "UTF-8"
  else render_args$encoding
  if (is.null(render_args$envir)) 
    render_args$envir <- parent.frame()
  if (!is.null(target_file)) 
    runtime <- rmarkdown:::yaml_front_matter(target_file, encoding)$runtime
  else runtime <- NULL
  if (rmarkdown:::is_shiny_prerendered(runtime)) {
    app <- shiny_prerendered_app.override(target_file, encoding = encoding, 
                                 render_args = render_args, renderer = renderer)
  } else {
    onStart <- function() {
      global_r <- rmarkdown:::file.path.ci(dir, "global.R")
      if (file.exists(global_r)) {
        source(global_r, local = FALSE)
      }
      shiny::addResourcePath("rmd_resources", rmarkdown:::rmarkdown_system_file("rmd/h/rmarkdown"))
    }
    on.exit({
      assign('evaluated_global_chunks', character(), rmarkdown:::.globals)
    }, add = TRUE)
    rcloud.shiny:::rcloud.shinyAppInternal(ui = rmarkdown:::rmarkdown_shiny_ui(dir, default_file), 
                                           uiPattern = "^/$|^/index\\.html?$|^(/.*\\.[Rr][Mm][Dd])$", 
                                           onStart = onStart, 
                                           server = rmarkdown_shiny_server.override(dir, 
                                                                                    default_file, encoding, auto_reload, render_args),
                                           renderer = renderer)
  }
}

# Tweaked rmarkdown:::rmarkdown_shiny_server function so it works in proxified environment
rmarkdown_shiny_server.override <- function (dir, file, encoding, auto_reload, render_args) 
{
  function(input, output, session) {
    # RCloud.mod: flexdashboard path is always '/', so it is fixed to single document.
    # path_info <- utils::URLdecode(session$request$PATH_INFO)
    # if (identical(substr(path_info, nchar(path_info) - 10, 
    #                      nchar(path_info)), "/websocket/")) {
    #   path_info <- substr(path_info, 1, nchar(path_info) - 
    #                         11)
    # }
    # if (!nzchar(path_info)) {
    #   path_info <- file
    # }
    path_info <- file
    file <- rmarkdown:::resolve_relative(dir, path_info)
    reactive_file <- if (auto_reload) 
      shiny::reactiveFileReader(500, session, file, identity)
    else function() {
      file
    }
    envir_global <- render_args[["envir"]]
    envir_server <- list2env(list(input = input, output = output, 
                                  session = session), parent = envir_global)
    render_args$envir <- new.env(parent = envir_server)
    doc <- shiny::reactive({
      out <- rmarkdown:::rmd_cached_output(file, encoding)
      output_dest <- out$dest
      if (out$cached) {
        if (nchar(out$resource_folder) > 0) {
          shiny::addResourcePath(basename(out$resource_folder), 
                                 out$resource_folder)
        }
        return(out$shiny_html)
      }
      if (!file.exists(dirname(output_dest))) {
        dir.create(dirname(output_dest), recursive = TRUE, 
                   mode = "0700")
      }
      resource_folder <- rmarkdown:::knitr_files_dir(output_dest)
      rmarkdown:::perf_timer_reset_all()
      dependencies <- list()
      shiny_dependency_resolver <- function(deps) {
        dependencies <<- deps
        list()
      }
      output_opts <- list(self_contained = FALSE, copy_resources = TRUE, 
                          dependency_resolver = shiny_dependency_resolver)
      message("\f")
      args <- rmarkdown:::merge_lists(list(input = reactive_file(), 
                                           output_file = output_dest, output_dir = dirname(output_dest), 
                                           output_options = output_opts, intermediates_dir = dirname(output_dest), 
                                           runtime = "shiny"), render_args)
      result_path <- shiny::maskReactiveContext(do.call(render, 
                                                        args))
      if (!rmarkdown:::dir_exists(resource_folder)) 
        dir.create(resource_folder, recursive = TRUE)
      shiny::addResourcePath(basename(resource_folder), 
                             resource_folder)
      dependencies <- append(dependencies, list(rmarkdown:::create_performance_dependency(resource_folder)))
      rmarkdown:::write_shiny_deps(resource_folder, dependencies)
      if (nzchar(Sys.getenv("RSTUDIO"))) 
        dependencies <- append(dependencies, list(rmarkdown:::html_dependency_rsiframe()))
      if (!isTRUE(out$cacheable)) {
        shiny::onReactiveDomainEnded(shiny::getDefaultReactiveDomain(), 
                                     function() {
                                       unlink(result_path)
                                       unlink(resource_folder, recursive = TRUE)
                                     })
      }
      rmarkdown:::shinyHTML_with_deps(result_path, dependencies)
    })
    doc_ui <- shiny::renderUI({
      doc()
    })
    if (exists("snapshotPreprocessOutput", asNamespace("shiny"))) {
      doc_ui <- shiny::snapshotPreprocessOutput(doc_ui, 
                                                function(value) {
                                                  value$html <- sprintf("[html data sha1: %s]", 
                                                                        digest::digest(value$html, algo = "sha1", 
                                                                                       serialize = FALSE))
                                                  value
                                                })
    }
    output$`__reactivedoc__` <- doc_ui
  }
}

# Overriden rmarkdown:::shiny_prerendered_app which uses rcloud.shiny to spin up shiny app
shiny_prerendered_app.override <- function (input_rmd, encoding, render_args, renderer = renderer) 
{
  html <- rmarkdown:::shiny_prerendered_html(input_rmd, encoding, render_args)
  deps <- attr(html, "html_dependencies")
  server_envir = new.env(parent = globalenv())
  html_lines <- strsplit(html, "\n", fixed = TRUE)[[1]]
  server_start_context <- rmarkdown:::shiny_prerendered_extract_context(html_lines, 
                                                            "server-start")
  server_start_code <- paste(c(server_start_context, rmarkdown:::shiny_prerendered_extract_context(html_lines, 
                                                                                       "data")), collapse = "\n")
  onStart <- function() {
    assign(".shiny_prerendered_server_start_code", server_start_code, 
           envir = server_envir)
    eval(parse(text = server_start_context), envir = server_envir)
    rmarkdown:::shiny_prerendered_data_load(input_rmd, server_envir)
    lockEnvironment(server_envir)
  }
  .server_context <- rmarkdown:::shiny_prerendered_extract_context(html_lines, 
                                                       "server")
  server_envir$.server_context <- .server_context
  server <- function(input, output, session) {
    eval(parse(text = .server_context))
  }
  environment(server) <- new.env(parent = server_envir)
  server_contexts <- c("server-start", "data", "server")
  html_lines <- rmarkdown:::shiny_prerendered_remove_contexts(html_lines, 
                                                  server_contexts)
  html <- HTML(paste(html_lines, collapse = "\n"))
  html <- htmltools::attachDependencies(html, deps)
  
  rcloud.shiny:::rcloud.shinyAppInternal(ui = function(req) html, 
                                         uiPattern = "^/$|^(/.*\\.[Rr][Mm][Dd])$", 
                                         onStart = onStart, 
                                         server = server,
                                         renderer = renderer)
}
