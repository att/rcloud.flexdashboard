
((function() {

    return {
        init: function(ocaps, k) {

            // Are we in the notebook?
            if (RCloud.UI.advanced_menu.add) {

                RCloud.UI.share_button.add({
                    'flexdashboard.html': {
                        sort: 1000,
                        page: 'shared.R/rcloud.flexdashboard/flexdashboard.html'
                    }
                });

            } else {
                onError = function(x) {
                    $('#rcloud-flexdashboard-loading').remove();
                    RCloud.UI.fatal_dialog(x.message, "Close")
                }

                oc = RCloud.promisify_paths(ocaps, [
                    ['renderFlexDashboard']
                ], true);

                window.RCloudFlexDashboard = window.RCloudFlexDashboard || {};
                window.RCloudFlexDashboard.renderFlexDashboard = function(x, y) {
                    oc.renderFlexDashboard(x, y).catch(onError).then(function() {});
                }
            }

            k()
        },

        render: function(target, html, k) {
            $('#rcloud-flexdashboard-loading').remove();
            $(target).html(html);
            k(null, target);
        }
    }

})());
