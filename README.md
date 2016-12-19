
<h1 align="center">
    <br>
    <img width="400" src="./inst/www/RCloud-flexo.png">
    <br>
</h1>

## Install

1. Install the `rcloud.rmd` package and this package on RCloud, using
   `devtools::install_github()` or `install-github.me`:
   ```R
   source("https://install-github.me/att/rcloud.rmd")
   source("https://install-github.me/att/rcloud.flexdashboard")
   ```
2. In the RCloud *Settings* menu, in the *Enable Extensions* line, add
   `rcloud.flexdashboard`, so that the package is loaded automatically.
3. Reload RCloud in the browser. This loads the package, and you should
   have the `flexdashboard.html` item in the special pages menu, right
   beside the RCloud logo in the top left corner

## Usage

R Markdown code chunks correspond to `R` notebook cells, and R Markdown
text corresponds to `markdown` notebook cells.

To show the dashboard, select the `flexdashboard.html` special page, and
then open it. `rcloud.flexdashboard` writes out an R Markdown file, calls
`rmarkdown::render` on it, and then sends the outputted standalone HTML,
embedded into an `iframe` to the browser.

## Developer notes

The package uses `rcloud.rmd` to export the notebook to R Markdown.

The only tricky part of the implementation is loading the `rcloud.flexdashboard`
package when in the dashboard. The `call_notebook` OCAP could be used to
evaluate the notebook, but this would require that the user loads the
`rcloud.flexdashboard` package manually in the notebook, and also that the user
calls a special function in the last cell to transfer the formatted notebook
to the browser. This is a solution that is used in the `rcloud.rcap` package.

Instead of this, we use a trick to trigger the loading of the package from JS.
For this we call `rcloud._ocaps.load_module_package()` which loads the package
as a side effect. We also need to define
```r
.rcloud.export.ocaps <- function() { list() }
```
in the R package to avoid an error, because `load_module_package()` evaluates
this.

When the package loads, we set up an OCAP in `.onLoad()`, and also assign it to
`window.RCloudFlexDashboard`, so that we can call it from JS:
```js
rcloud._ocaps.load_module_package(
    "rcloud.flexdashboard",
    function(x) {
        window.RCloudFlexDashboard.renderFlexDashboard(
            notebook,
            version,
            function(x) { console.log(x); }
        );
    }
);
```

The OCAP that we call simply saves the notebook to an R Markdown file (without
actually evaluating it), and then calls `rmarkdown::render()` on it to create
a standalone HTML file, which is then transmitted to the browser.

While this implementation works for authenticated users, it does not currently
work for anonymous users, and it might be rewritten completely, see e.g.
https://github.com/att/rcloud.flexdashboard/issues/13
