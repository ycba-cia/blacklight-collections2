
var viewer = [];
var objectImages = [];

function updateImageData( id ,cds,type) {
    $("#osd-hook").empty();
    objectImages = [];
    viewer = [];

    $("#non-image-section").hide();
    $("#image-section").hide();
    $("#ycba-downloads").hide();

    var manifest = "https://manifests.britishart.yale.edu/manifest/" + id;
    $.ajax({
        type: "GET",
        async: true,
        crossDomain: false,
        url: manifest
    }).success(function(message,text,jqXHR){

        var iiif_info = [];
        var caption_info = [];
        $.each(message.sequences[0].canvases,function(i,v) {
            iiif_info.push(""+ v.images[0].resource.service['@id']+"/info.json");
            var label1 = v.label;
            if (label1.length > 0) {
                label1 = label1.charAt(0).toUpperCase() + label1.slice(1);
            }
            caption_info.push(label1);
        });

        viewer = OpenSeadragon({
            id: "osd-hook",
            prefixUrl: "/assets/osd/",
            sequenceMode: true,
            tileSources: iiif_info
        });

        //accessibility
        var zoomin = document.querySelector('[title="Zoom in"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Zoom in");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");
        var zoomin = document.querySelector('[title="Zoom out"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Zoom out");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");
        var zoomin = document.querySelector('[title="Go home"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Go home");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");
        var zoomin = document.querySelector('[title="Toggle full page"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Toggle full page");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");
        var zoomin = document.querySelector('[title="Previous page"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Previous page");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");
        var zoomin = document.querySelector('[title="Next page"]');
        zoomin.setAttribute("tabindex",0);
        zoomin.setAttribute("role","button");
        zoomin.setAttribute("aria-label","Next page");
        remove_attribute_from_elements(zoomin.getElementsByTagName("img"),"alt");

        var parent_element = document.getElementById("osd-hook");
        parent_element.removeAttribute("aria-live");
        var element = parent_element.getElementsByTagName("label"), index;
        for (index = element.length - 1; index >= 0; index--) {
            element[index].parentNode.removeChild(element[index]);
        }

        $("#osd-caption").empty().append(caption_info[0]);
        viewer.addHandler('page', function(event) {
            $("#osd-caption").empty().append(caption_info[event.page]);
            setDLMetadata(event.page);
        });

        $("#ycba-thumbnail-controls").empty().append(
            "<a target='_blank' class='' href='http://mirador.britishart.yale.edu/?manifest=" + manifest + "'><img src='https://manifests.britishart.yale.edu/logo-iiif.png' class='img-responsive' alt='IIIF Manifest'></a>");
        
        $("#image-section").show();
        
        cdsData(cds,"osd");
        setDLMetadata(0);
        //alert("got object images" + objectImages.length);
        if (objectImages.length > 1) {
            var html = "";
            $.each(objectImages, function(index, data){
                //console.log(objectImages);
                var caption = data['metadata']['caption'];
                if (!caption || 0 === caption.length) {
                    caption = "&nbsp;";
                } else {
                    caption = caption.charAt(0).toUpperCase() + caption.slice(1);
                }
                var imgalt = String(index+1) + " of " + String(objectImages.length);
                html += "<div class='tile'>"
                    //+ "<figure class='tile__media' onclick='setMainImage(objectImages[" + index + "], " + index + ");''>"
                    + "<figure tabindex='0' class='tile__media' onclick='osdGoToPage("+index+")'>"
                    +"<img class='tile__img' src='" + data[1]['url'] + "' alt='"+imgalt+"' />"
                    + "<div class='tile__details'>"
                    + "<figcaption class='tile__title'>"+caption+"</figcaption>"
                    + "</div>"
                    +"</div>";
            });
            html += "";
            $("#ycba-thumbnail-row-inner").append(html);
            $(".tile__media").keypress(function (e) {
                var key = e.which;
                if(key == 13)  // the enter key code
                {
                    $(this).click();
                    return false;
                }
            });
        }
    }).error(function(context) {
        //alert("noway");
        cdsData(cds,"cds");
    });
}

function remove_attribute_from_elements(e,a) {
    for (var i=0, max=e.length; i < max; i++) {
        e[i].removeAttribute(a);
    }
}

function fancybox(index) {
    var fbsrc = [];
    $.each(objectImages, function (index, derivative) {
        var caption;
        var image = {
            opts: {}
        };
        if (derivative['metadata']) {
            caption = derivative['metadata']['caption']
            if (caption.length > 0) {
                caption = caption.charAt(0).toUpperCase() + caption.slice(1);
            }
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

function cdsData(url,type) {
    console.log("URL:"+url + "  " + type);
    if (objectImages.length == 0) {
        $.ajax({
            type: "GET",
            async: false,
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
                    image['url'] = value['url'].replace(/^http:\/\//i, 'https://');
                    derivatives[index] = image;
                    //console.log("IMG:"+image['url']);
                });
                objectImages[index] = derivatives;
            });
            //console.log(objectImages);
            if (type=="cds") {
                renderCdsImages();
            }
        });
    }
}

function renderCdsImages() {
    html = "";
    if (objectImages.length > 0) {
        var data = objectImages[0];
        setMainImage(data,0);
    } else {
    }


    if (objectImages.length > 1) {
        var html = "";
        $.each(objectImages, function(index, data){
            //console.log(objectImages);
            var caption = data['metadata']['caption'];
            if (!caption || 0 === caption.length) {
                caption = "&nbsp;";
            } else {
                caption = caption.charAt(0).toUpperCase() + caption.slice(1);
            }
            if (caption.length > 48) {
                caption = caption.substring(0,48) + "...";
            }
            var imgalt = String(index+1) + " of " + String(objectImages.length);
            html += "<div class='tile'>"
                + "<figure tabindex='0' class='tile__media' onclick='setMainImage(objectImages[" + index + "], " + index + ");''>"
                //+ "<figure class='tile__media' onclick='osdGoToPage("+index+")'>"
                +"<img class='tile__img' src='" + data[1]['url'] + "' alt='"+imgalt+"' />"
                + "<div class='tile__details'>"
                + "<figcaption class='tile__title'>"+caption+"</figcaption>"
                + "</div>"
                +"</div>";
        });
        html += "";
        $("#ycba-thumbnail-row-inner").append(html);
        $(".tile__media").keypress(function (e) {
            var key = e.which;
            if(key == 13)  // the enter key code
            {
                $(this).click();
                return false;
            }
        });
    }

    if (objectImages.length > 0) {
        $("#image-section").show();
    } else {
        $("#non-image-section").show();
    }
}

function osdGoToPage(index) {
    //console.log(objectImages[index][3]['format']);
    viewer.goToPage(index);
    setDLMetadata(index);
    $(window).scrollTop(0);
}

function setDLMetadata(index) {
    //alert(image.inspect);
    var image = objectImages[index];
    var jpeg = image[3] || image[2] || image[1];
    var tiff = image[6];
    var suppress_jpeg_dl = false;
    if (image[3]==null) {
        suppress_jpeg_dl = true;
    }
    var format = jpeg['format'];
    var sizeBytes = jpeg['size'];
    var pixelsX = jpeg['width'];
    var pixelsY = jpeg['height'];
    var sizeMBytes = (sizeBytes / 1000000).toFixed(2) + " MB";
    var pixels = pixelsX + " x " + pixelsY + "px";
    var jpegImageInfo = format + ", " + pixels +", " + sizeMBytes;
    if (suppress_jpeg_dl) {
        jpegImageInfo = "JPEG image not available";
    }
    console.log(jpegImageInfo);

    var tiffImageInfo = "";
    if (tiff) {
        format = tiff['format'];
        sizeBytes = tiff['size'];
        pixelsX = tiff['width'];
        pixelsY = tiff['height'];
        sizeMBytes = (sizeBytes / 1000000).toFixed(2) + " MB";
        pixels = pixelsX + " x " + pixelsY + "px";
        tiffImageInfo = format + ", " + pixels + ", " + sizeMBytes;
    } else {
        tiffImageInfo = "TIFF image not available";
    }
    console.log(tiffImageInfo);
    if (tiff || suppress_jpeg_dl == false) {
        $("#ycba-downloads").show();
    }

    var dl_url_jpeg = jpeg['url'].split("/").slice(0,-1).join("/").concat("/"+jpeg['url'].split("/")[7]);
    var dl_url_tiff = jpeg['url'].split("/").slice(0,-1).join("/").concat("/6");
    var dl_name = dl_url_jpeg.split("/")[5];

    console.log(dl_url_jpeg);
    console.log(dl_url_tiff);

    var tiff_info =  "";
    if (tiff) {
        tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "' target=\"_blank\">";
        tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm'>TIFF</button>";
        tiff_info += "</a>";
    } else {
        tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "' target=\"_blank\">";
        tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm' disabled>TIFF</button>";
        tiff_info += "</a>";
    }
    $("#tiff-dl-info").text(tiffImageInfo);
    var jpeg_info = "";
    if (suppress_jpeg_dl) {
        jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "' target=\"_blank\">";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm' disabled>JPEG</button>";
        jpeg_info += "</a>"
    } else {
        jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "' target=\"_blank\">";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm'>JPEG</button>";
        jpeg_info += "</a>"
    }
    $("#jpeg-dl-info").text(jpegImageInfo);

    $("#tiff-container").html(tiff_info);
    $("#jpeg-container").html(jpeg_info);
}

function setMainImage(image, index) {
    //alert(index);
    var derivative = image[2] || image[1];
    var metadata = image['metadata'];
    var large_derivative = image[3] || image[2] || image[1];
    var suppress_jpeg_dl = false;
    if (image[3]==null) {
        suppress_jpeg_dl = true;
    }
    var tiff_image =  image[6];
    var next = index+1;
    var prev = index-1;
    if (next > objectImages.length) {
        next = objectImages.length;
    }
    if (prev < 0) {
        prev = 0;
    }
    //console.log('len:'+objectImages.length);
    var fit = true;
    if (document.getElementById("main-image")!==null) {
        if (document.getElementById("main-image").classList.contains("fitscreen")) {
            fit = true;
        }
    }

    if (derivative) {
        var html = "";
        //for fancybox add to img tag: onclick='fancybox(" + index + ");'
        html += "<div id='left-nav' tabindex='0' onclick='setMainImage(objectImages[" + prev + "], " + prev + ")'>  </div>";
        html += "<div id='right-nav' tabindex='0' onclick='setMainImage(objectImages[" + next + "], " + next + ")'>  </div>";

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
        if (suppress_jpeg_dl) {
            jpegImageInfo = "JPEG image not available";
        }

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
        if (suppress_jpeg_dl==false || tiff_image) {
            $("#ycba-downloads").show();
        }
        var tiff_info =  "";
        if (tiff_image) {
            tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "' target=\"_blank\">";
            tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm'>TIFF</button>";
            tiff_info += "</a>";
        } else {
            tiff_info += "<a href='" + dl_url_tiff + "' download='" + dl_name + "' target=\"_blank\">";
            tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm' disabled>TIFF</button>";
            tiff_info += "</a>";
        }
        $("#tiff-dl-info").text(tiffImageInfo);
        var jpeg_info = "";
        if (suppress_jpeg_dl) {
            jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "' target=\"_blank\">";
            jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm' disabled>JPEG</button>";
            jpeg_info += "</a>"
        } else {
            jpeg_info += "<a href='" + dl_url_jpeg + "' download='" + dl_name + "' target=\"_blank\">";
            jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm'>JPEG</button>";
            jpeg_info += "</a>"
        }
        $("#jpeg-dl-info").text(jpegImageInfo);

        $("#tiff-container").html(tiff_info);
        $("#jpeg-container").html(jpeg_info);

        if (objectImages.length==1) {
            $("#left-nav").hide();
            $("#right-nav").hide();
        }
        if (index==0) {
            $("#left-nav").hide();
        }
        if ((objectImages.length - 1) == index) {
            $("#right-nav").hide();
        }

        $("#right-nav").keypress(function(e) {
            if (e.which == 13) {
                setMainImage(objectImages[next], next);
            }
        });

        $("#left-nav").keypress(function(e) {
            if (e.which == 13) {
                setMainImage(objectImages[prev], prev);
            }
        });

    }
    
    if (metadata) {
        var caption = metadata['caption'] || '&nbsp;';
        if (caption.length > 0) {
            caption = caption.charAt(0).toUpperCase() + caption.slice(1);
        }
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

window.addEventListener("message", (event) => {
    //console.log("postMessage received");
    //console.log(event);
    $("#selected-image-index").hide();
    $("#dlselect-info").hide();
    $("#selected-image-index").text(event.data);
});

function select_one_dl(download,id,doc) {
    var index = $("#selected-image-index").text();
    $("#dlselect-info").show();
    selectdl(download[index],id,doc);
}
//cds2
function selectdl(download,id,doc) {
    //console.log ("download:" + download);
    //console.log ("download:" + download[0]);
    //console.log ("download:" + download[1]);
    //console.log ("download:" + download[2]);
    //console.log ("download:" + download[3]);
    //[count,caption,jpeg,tiff]

    var index = download[0]-1
    var jpeg_info = "";
    $("#dlselect-info").text(download[0] + ". "+download[1]);

    var recordtype = doc["recordtype_ss"][0];
    if (recordtype=="lido") {
        var cap1 = [];
        if (doc["author_ss"] != null) { cap1.push(doc["author_ss"][0]); }
        if (doc["title_ss"] != null) { cap1.push(doc["title_ss"][0]); }
        //if (download != null) { cap1.push(download[1]); } //don't display caption as of 1/23/2023
        if (doc["publishDate_ss"] != null) { cap1.push(doc["publishDate_ss"][0]); }
        if (doc["format_ss"] != null) { cap1.push(doc["format_ss"][0]); }
        if (doc["credit_line_ss"] != null) { cap1.push(doc["credit_line_ss"][0]); }
        if (doc["callnumber_ss"] != null) { cap1.push(doc["callnumber_ss"][0]); }
        $("#caption-dl-info").text(cap1.join(", ") + ".");
    }
    if (recordtype=="marc") {
        var cap1 = [];
        if (doc["author_ss"] != null) { cap1.push(doc["author_ss"][0]); }
        if (doc["titles_primary_ss"] != null) { cap1.push(doc["titles_primary_ss"][0]); }
        //if (download != null) { cap1.push(download[1]); }////don't display caption as of 1/23/2023
        if (doc["edition_ss"] != null) { cap1.push(doc["edition_ss"][0]); }
        if (doc["publisher_ss"] != null) { cap1.push(doc["publisher_ss"][0]); }
        if (doc["credit_line_ss"] != null) { cap1.push(doc["credit_line_ss"][0]); }
        $("#caption-dl-info").text(cap1.join(", ") + ".");
    }
    if (download[2].length == 0) {
        jpeg_info += "<a href='" + download[2] + "' download='" + download[1] + "' target=\"_blank\">";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm' disabled>JPEG</button>";
        jpeg_info += "</a>"
    } else {
        jpeg_info += "<a href='" + download[2] + "' download='" + download[1] + "' target=\"_blank\">";
        jpeg_info += "<button id='jpeg-dl-button' type='button' class='btn btn-primary btn-sm'>JPEG</button>";
        jpeg_info += "</a>"
        //$("#jpeg-dl-info").text(download[0] + ". "+download[1]); deprecated
    }
    $("#jpeg-container").html(jpeg_info);

    var tiff_info =  "";
    if (download[3].length == 0) {
        tiff_info += "<a href='" + download[3] + "' download='" + download[1] + "' target=\"_blank\">";
        tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm' disabled>TIFF</button>";
        tiff_info += "</a>";
    } else {
        tiff_info += "<a href='" + download[3] + "' download='" + download[1] + "' target=\"_blank\">";
        tiff_info += "<button id='tiff-dl-button' type='button' class='btn btn-primary btn-sm'>TIFF</button>";
        tiff_info += "</a>";
        //$("#tiff-dl-info").text(download[0] + ". "+download[1]); deprecated
    }
    $("#tiff-container").html(tiff_info);

    var print_info =  "";
    var print_info_all = "";
    var print_path = "/print/"+id+"/1/"+index+"?caption="+download[1];
    var print_path_all = "/print/"+id+"/9998/9998";
    if (download[2].length == 0) {
        print_info += "<a href='"+print_path+"' target=\"_blank\">";
        print_info += "<button id='print-button' type='button' class='btn btn-primary btn-sm' disabled>Print</button>";
        print_info += "</a>";
        print_info_all += "<a href='"+print_path_all+"' target=\"_blank\">";
        print_info_all += "<button id='print-button-all' type='button' class='btn btn-primary btn-sm' disabled>Print All</button>";
        print_info_all += "</a>";
    } else {
        print_info += "<a href='"+print_path+"' target=\"_blank\">";
        print_info += "<button id='print-button' type='button' class='btn btn-primary btn-sm'>Print</button>";
        print_info += "</a>";
        print_info_all += "<a href='"+print_path_all+"' target=\"_blank\">";
        print_info_all += "<button id='print-button-all' type='button' class='btn btn-primary btn-sm'>Print All</button>";
        print_info_all += "</a>";
        //$("#print-info").text(download[0] + ". "+download[1]);deprecated
    }
    $("#print-container").html(print_info);
    $("#print-container-all").html(print_info_all);

}

