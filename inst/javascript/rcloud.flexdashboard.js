
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

                oc = RCloud.promisify_paths(ocaps, [
                    ['renderFlexDashboard']
                ], true);

                window.RCloudFlexDashboard = window.RCloudFlexDashboard || {};
                window.RCloudFlexDashboard.renderFlexDashboard = function(x, y) {
                    oc.renderFlexDashboard(x, y).then(function() {});
                }
            }

            k()
        },

        render: function(target, html, k) {
            $(target).html(html);
            k(null, target);
        }
    }

})());
