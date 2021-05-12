/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

console.log('Hello World from Webpacker');

import Mirador from 'mirador/dist/es/src/index.js';
import miradorDownloadPlugins from 'mirador-dl-plugin';

window.onload = () => {
    const manifest = document.querySelector("#manifest_es6").dataset.manifest;
    //console.log(manifest);
    const anchor = document.querySelector("#anchor_es6").dataset.anchor;
    //console.log(anchor);
    var thumbposition = "";
    var show_osd_nav = "";
    if (anchor=="mirador") {
        thumbposition = "far-bottom";
        show_osd_nav = false;
    } else {
        thumbposition = "off";
        show_osd_nav = false;
    }
    const config = {
        "id": anchor,
        "selectedTheme": "light",
        "manifests": {
            "manifest": {
                "provider": "Yale Center for British Art"
            }
        },
        "window": {
            "allowClose": false,
            "allowFullscreen": true,
            "allowMaximize": false
        },
        "windows": [
            {
                "loadedManifest": manifest,
                "canvasIndex": 0,
                "thumbnailNavigationPosition": thumbposition,
                "allowClose": false

            }
        ],
        "workspaceControlPanel": {
            "enabled": false
        },
        "workspace": {
            "showZoomControls": true
        },
        "osdConfig": {
            "showNavigationControl": show_osd_nav
        }
    };

    Mirador.viewer(config,[miradorDownloadPlugins]);
}


