


function updateImageData( id ) {
    var manifest = "https://manifests.britishart.yale.edu/manifest/" + id;
    $.ajax({
        type: "HEAD",
        async: true,
        crossDomain: false,
        url: manifest
    }).success(function(message,text,jqXHR){
        $("#ycba-thumbnail-controls").empty().append(
            "<a target='_blank' class='' href='http://mirador.britishart.yale.edu/?manifest=" + manifest + "'><img src='https://manifests.britishart.yale.edu/logo-iiif.png' class='img-responsive' alt='IIIF Manifest'></a>");
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
    console.log("URL:"+url);
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
                    //console.log("IMG:"+image['url']);
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
    } else {
        $("#image-section").hide();
    }

    if (objectImages.length > 1) {
        var html = "";
        $.each(objectImages, function(index, data){
            //console.log(objectImages);
            var caption = data['metadata']['caption'];
            if (!caption || 0 === caption.length) {
                caption = "no caption";
            }
            html += "<div class='tile'>"
                + "<figure class='tile__media' onclick='setMainImage(objectImages[" + index + "], " + index + ");''>"
                +"<img class='tile__img' src='" + data[1]['url'] + "' alt='"+caption+"' />"
                + "<div class='tile__details'>"
                + "<figcaption class='tile__title'>"+caption+"</figcaption>"
                + "</div>"
                +"</div>";
        });
        html += "";
        $("#ycba-thumbnail-row-inner").append(html);
    }
}

function setMainImage(image, index) {
    //alert(index);
    var derivative = image[2] || image[1];
    var metadata = image['metadata'];
    var large_derivative = image[3] || image[2] || image[1];

    if (derivative) {
        var html = "";
        //for fancybox add to img tag: onclick='fancybox(" + index + ");'
        html += "<img class='img-responsive hidden-sm center-block' src='" + large_derivative['url'] + "' alt='main image' />";
        html += "<img class='img-responsive visible-sm-block lazy center-block' data-original='" + large_derivative['url'] + "' alt=''main image' />";
        $("#ycba-main-image").html(html);
        var dl_url_jpeg = derivative['url'].split("/").slice(0,-1).join("/").concat("/3");
        var dl_url_tiff = derivative['url'].split("/").slice(0,-1).join("/").concat("/6");
        var dl_name = dl_url_jpeg.split("/")[5];
        //var dl_html_jpeg = "<a href='" + dl_url_jpeg + "' download='" + dl_name + "'>download jpeg</a>";
        //var dl_html_tiff = "<a href='" + dl_url_tiff + "' download='" + dl_name + "'>download tiff</a>";
        //$("#ycba-downloads").html(dl_html_jpeg + " | " + dl_html_tiff);

        var format = large_derivative['format'];
        var sizeBytes = large_derivative['sizeBytes'];
        var pixelsX = large_derivative['pixelsX'];
        var pixelsY = large_derivative['pixelsY'];
        //WIP 3/8/19 - info, tiff info, deal w/caption metadata, put in partial

        var tiff_info =  "";
        tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "'>";
        tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm'>TIFF</button>";
        tiff_info += "</a>";
        var jpeg_info = "";
        jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "'>";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm'>JPEG</button>";
        jpeg_info += "</a>"
        $("#tiff-container").html(tiff_info);
        $("#jpeg-container").html(jpeg_info);
    }

    if (metadata) {
        var caption = metadata['caption'] || '&nbsp;';
        if (caption) {
            $("#ycba-main-image-caption").html(caption);
        }
    }
    $('body').scrollTop(0);
    $("img.lazy").lazyload();
}

function applyLightSlider() {
    $("#thumbnailselector").lightSlider({
        item: 4,
        slideMargin: 10
    });
}

