


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
        setMainImage(data,0);
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
    var tiff_image =  image[6];
    var next = index+1;
    var prev = index-1;
    if (next > objectImages.length) {
        next = objectImages.length;
    }
    if (prev < 0) {
        prev = 0;
    }
    console.log('len:'+objectImages.length);
    var fit = false;
    if (document.getElementById("main-image")!==null) {
        if (document.getElementById("main-image").classList.contains("fitscreen")) {
            fit = true;
        }
    }

    if (derivative) {
        var html = "";
        //for fancybox add to img tag: onclick='fancybox(" + index + ");'
        html += "<div id='left-nav' onclick='setMainImage(objectImages[" + prev + "], " + prev + ")'>  </div>";
        html += "<div id='right-nav' onclick='setMainImage(objectImages[" + next + "], " + next + ")'>  </div>";

        if (fit) {
            html += "<img id='main-image' onclick='toggleImageSize()' class='img-responsive hidden-sm center-block fitscreen' src='" + large_derivative['url'] + "' alt='main image' />";
            html += "<img id='main-image' onclick='toggleImageSize()' class='img-responsive visible-sm-block lazy center-block fitscreen' data-original='" + large_derivative['url'] + "' alt=''main image' />";

        } else {
            html += "<img id='main-image' onclick='toggleImageSize()' class='img-responsive hidden-sm center-block' src='" + large_derivative['url'] + "' alt='main image' />";
            html += "<img id='main-image' onclick='toggleImageSize()' class='img-responsive visible-sm-block lazy center-block' data-original='" + large_derivative['url'] + "' alt=''main image' />";
        }
        $("#ycba-main-image").html(html);
        var dl_url_jpeg = derivative['url'].split("/").slice(0,-1).join("/").concat("/"+large_derivative['url'].split("/")[7]);
        var dl_url_tiff = derivative['url'].split("/").slice(0,-1).join("/").concat("/6");
        var dl_name = dl_url_jpeg.split("/")[5];
        //var dl_html_jpeg = "<a href='" + dl_url_jpeg + "' download='" + dl_name + "'>download jpeg</a>";
        //var dl_html_tiff = "<a href='" + dl_url_tiff + "' download='" + dl_name + "'>download tiff</a>";
        //$("#ycba-downloads").html(dl_html_jpeg + " | " + dl_html_tiff);

        var format = large_derivative['format'];
        var sizeBytes = large_derivative['size'];
        var pixelsX = large_derivative['width'];
        var pixelsY = large_derivative['height'];
        var sizeMBytes = (sizeBytes / 1000000).toFixed(2) + " MB";
        var pixels = pixelsX + " x " + pixelsY + "px";
        var jpegImageInfo = format + ", " + pixels +", " + sizeMBytes;

        var tiffImageInfo = "";
        if (tiff_image) {
            format = tiff_image['format'];
            sizeBytes = tiff_image['size'];
            pixelsX = tiff_image['width'];
            pixelsY = tiff_image['height'];
            sizeMBytes = (sizeBytes / 1000000).toFixed(2) + " MB";
            pixels = pixelsX + " x " + pixelsY + "px";
            tiffImageInfo = format + ", " + pixels + ", " + sizeMBytes;
        } else {
            tiffImageInfo = "TIFF image not available";
        }
        //WIP 3/8/19 - info, tiff info, deal w/caption metadata, put in partial

        var tiff_info =  "";
        if (tiff_image) {
            tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "'>";
            tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm'>TIFF</button>";
            tiff_info += "</a>";
        } else {
            tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "'>";
            tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm' disabled>TIFF</button>";
            tiff_info += "</a>";
        }
        $("#tiff-dl-info").text(tiffImageInfo);
        var jpeg_info = "";
        jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "'>";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm'>JPEG</button>";
        jpeg_info += "</a>"
        $("#jpeg-dl-info").text(jpegImageInfo);

        $("#tiff-container").html(tiff_info);
        $("#jpeg-container").html(jpeg_info);

        if (objectImages.length==1) {
            $("#left-nav").hide();
            $("#right-nav").hide();
        }
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

function toggleImageSize() {
    var image = document.getElementById("main-image");
    image.classList.toggle("fitscreen");
    /*
    var image_width = image.clientWidth;
    var container = document.getElementById("content");
    var container_width = container.clientWidth;
    var margin = (container_width - image_width)/2;
    var margin_px = margin + "px";

    var left_nav = document.getElementById("left-nav");
    var right_nav = document.getElementById("right-nav");
    left_nav.style.marginLeft = margin_px;
    right_nav.style.marginRight = margin_px;
    console.log("size:"+image_width);
    console.log("screen:"+container_width);
    console.log("marginpx:"+margin_px);
    */

}

function applyLightSlider() {
    $("#thumbnailselector").lightSlider({
        item: 4,
        slideMargin: 10
    });
}

