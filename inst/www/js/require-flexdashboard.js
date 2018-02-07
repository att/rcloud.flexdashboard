requirejs.config(requirejs_config_obj); // jshint ignore:line
var deps = common_deps; // jshint ignore:line
deps.push(
    // rcloud's mini.js and bundle
    '../../shared.R/rcloud.flexdashboard/js/rcloud-flexdashboard', 'rcloud_bundle');
start_require(deps); // jshint ignore:line