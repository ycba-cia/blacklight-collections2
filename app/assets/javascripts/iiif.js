


function updateImageData( id ) {
    var manifest = "http://manifests.britishart.yale.edu/manifest/" + id;
    $.ajax({
        type: "HEAD",
        async: true,
        crossDomain: false,
        url: manifest
    }).success(function(message,text,jqXHR){
        $("#ycba-thumbnail-controls").append(
            "<a target='_blank' class='' href='http://mirador.britishart.yale.edu/?manifest=" + manifest + "'><img src='http://manifests.britishart.yale.edu/logo-iiif.png' class='img-responsive' alt='IIIF Manifest'></a>");
    });
}

var objectImages = [];

function fancybox(index) {
    var fbsrc = [];
    $.each(objectImages, function (index, derivative) {
        var caption;
        var image = {
            opts: {}
        };
        if (derivative['metadata']) {
            caption = derivative['metadata']['caption']
        }
        var size = 0;
       $.each(derivative, function(index, d) {
           if (d != null && d['size'] > size && d['format'] === 'image/jpeg') {
               image['src'] = d['url'];
           }
       });
       console.log(image['src']);
       if (image['src'] != null) {
           image['opts'] = { iframe: { preload: true }, slideClass : 'fbslide', caption: caption, margin: [100,100]};
           image['type'] = 'image';
           fbsrc.push(image);
       }
    });
    $.fancybox.open(fbsrc, {}, index);
}

function cdsData(url) {
    if (objectImages.length == 0) {
        $.ajax({
            type: "GET",
            async: true,
            crossDomain: true,
            url: url
        }).success(function (data, textStatus, jqXHR) {
            $.each(data, function (index, value) {
                var d = value['derivatives'];
                var derivatives = [];
                derivatives['metadata'] = value['metadata'];
                $.each(d, function (index, value) {
                    var image = [];
                    image['format'] = value['format'];
                    image['size'] = value['sizeBytes'];
                    image['id'] = value['contentId'];
                    image['width'] = value['pixelsX'];
                    image['height'] = value['pixelsY'];
                    image['url'] = value['url'];
                    derivatives[index] = image;
                    //console.log(image);
                });
                objectImages[index] = derivatives;
            });
            //console.log(objectImages);
            renderCdsImages();
        });
    }
}

function renderCdsImages() {
    html = "";

    if (objectImages.length > 0) {
        var data = objectImages[0];
        setMainImage(data);
    }

    if (objectImages.length > 1) {
        var html = "";
        $.each(objectImages, function(index, data){
            //console.log(objectImages);
            html += "<div class='col-xs-6 col-sm-3 col-md-6'>"
                + "<div onclick='setMainImage(objectImages[" + index + "], " + index + ");'><img class=' img-responsive' src='"
                + data[1]['url'] + "'/></div>"
                + data['metadata']['caption']
                + "</div>";
            if ( (index + 1) % 4 == 0) {
                html += "<div class='clearfix visible-xs-block visible-sm-block visible-med-block visible-lg-block'></div>";
            } else if ( (index + 1) % 2 == 0) {
                html += "<div class='clearfix visible-med-block visible-lg-block'></div>";
            }
        });
        html += "";
        $("#ycba-thumbnail-row").append(html);
    }
}

function setMainImage(image, index) {
    var derivative = image[2] || image[1];
    var metadata = image['metadata'];
    var large_derivative = image[3] || image[2] || image[1];

    if (derivative) {
        var html = "";
        html += "<img class='img-responsive hidden-sm' src='" + derivative['url'] + "' onclick='fancybox(" + index + ");' />";
        html += "<img class='img-responsive visible-sm-block lazy' data-original='" + large_derivative['url'] + "' onclick='fancybox(" + index + ");'/>";
        $("#ycba-main-image").html(html);
    }

    if (metadata) {
        var caption = metadata['caption'] || '&nbsp;';
        if (caption) {
            $("#ycba-main-image-caption").html(caption);
        }
    }
    $("img.lazy").lazyload();
}

function applyLightSlider() {
    $("#thumbnailselector").lightSlider({
        item: 4,
        slideMargin: 10
    });
}

