// jshint ignore: start
function main() {
    function getURLParameter(name) {
        return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search)||[,""])[1].replace(/\+/g, '%20'))||null;
    }

    function getQueryArgs() {
        var r, res = {}, s = location.search;
        while ((r = (new RegExp('[?|&]([^=&]+?)=([^&;#]+)(.*)').exec(s))) !== null) {
            res[decodeURIComponent(r[1])] = decodeURIComponent(r[2]);
            s = r[3];
        }
        return res;
    }

    function onError(e) {
        $('#rcloud-flexdashboard-loading').remove();
        RCloud.UI.fatal_dialog(e.message, "Close");
    }

    rclient = RClient.create({
        debug: false,
        mode: "addons", // Do load addons. Don't do much else.
        host: location.href.replace(/^http/,"ws").replace(/#.*$/,""),
        on_connect: function(ocaps) {
            rcloud = RCloud.create(ocaps.rcloud);
            var promise;
            if (rcloud.authenticated) {
                promise = rcloud.session_init(rcloud.username(), rcloud.github_token());
            } else {
                promise = rcloud.anonymous_session_init();
            }
            promise = promise.then(function(hello) {
                rclient.post_response(hello);
            });

            // resolve(rcloud.init_client_side_data()); // what was this for?!?

            var notebook = getURLParameter("notebook"),
                version = getURLParameter("version");
            var tag = getURLParameter("tag");
            if(!version && tag) {
                promise = promise.then(function() {
                    return rcloud.get_version_by_tag(notebook, tag)
                        .then(function(v) {
                            version = v;
                        });
                });
            };
            promise = promise.then(function() {
                // if rcloud.flexdashboard is properly loaded as an rcloud addon, it
                // will have already loaded and installed its ocap during session_init
                if(!window.RCloudFlexDashboard.renderFlexDashboard)
                    throw new Error('rcloud.flexdashboard must be specified in rcloud.alluser.addons');
                window.RCloudFlexDashboard.renderFlexDashboard(
                    notebook,
                    version,
                    function(x) { console.log(x); }
                );
            });
            promise = promise.catch(onError);
            return true;
        },
        on_data: RCloud.session.on_data,
        on_oob_message: RCloud.session.on_oob_message,
        on_error: function(msg, status_code) {
            // debugger;
            if (msg == 'Login failed. Shutting down!') {
                window.location =
                    (window.location.protocol +
                     '//' + window.location.host +
                     '/login.R?redirect=' +
                     encodeURIComponent(window.location.pathname + window.location.search));
                return true;
            } else
                return false;
        }
    });
}
