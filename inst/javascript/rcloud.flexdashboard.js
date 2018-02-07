
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
                    RCloud.UI.fatal_dialog(x.message, "Close");
                };

                oc = RCloud.promisify_paths(ocaps, [
                    ['renderFlexDashboard']
                ], true);

                window.RCloudFlexDashboard = window.RCloudFlexDashboard || {};
                window.RCloudFlexDashboard.renderFlexDashboard = function(x, y) {
                    oc.renderFlexDashboard(x, y).catch(onError).then(function() {});
                };
            }

            k();
        },

        render: function(target, html, k) {
            $('#rcloud-flexdashboard-loading').remove();
            var content = "<iframe frameBorder=\"0\" width=\"100%\" height=\"100%\" srcdoc=\"" + html + "\"></iframe>";
            var parsed = $(html);
            var title = parsed.filter('title').text();
            if(title!=="") {
                document.title = title + " - RCloud";
            } else {
                document.title = "RCloud flexdashboard";
            }
            $(target).html(content);
            k(null, target);
        },
        progress: function(target, html, k) {
            $('#rcloud-flexdashboard-progress')
                .css('visibility', 'visible')
                .html(html);
            k(null, target);
        },
        
        renderShinyUrl: function(target, url, k) {
            $('#rcloud-flexdashboard-loading').remove();
            var content = '<iframe src="'+url+'" class="rcloud-shiny" frameBorder="0" style="position: absolute; left: 0px; top: 0px; width: 100%; height: 100%;"></iframe>';
            document.title = "RCloud flexdashboard";
            $(target).html(content);
            k(null, target);
        }
    };

})());
