//function below used for exhibition and citation
function toggle_show_field(classname) {
    console.log("test toggle_citation");
    var closed = document.getElementsByClassName("blacklight-"+classname+"-closed")[0];
    var open = document.getElementsByClassName("blacklight-"+classname+"-open")[0];
    //kluge
    if (closed.style.display == "") {
        closed.style.display = "block";
    }
    //console.log(closed.style.display);

    if (closed.style.display === "block") {
        //console.log("opening");
        closed.style.display = "none";
        open.style.display = "block";
    } else {
        //console.log("closing");
        open.style.display = "none";
        closed.style.display = "block";
    }
}

function skip_to_results() {
    var thumbs = $(".thumbnail > a").first();
    thumbs.focus();
    return false;
}

function skip_to_splash_image() {
    var splash = $("div.item.active > a").first();
    splash.focus();
    return false;
}

function skip_to_osd() {
    //var zoomin = document.querySelector('[title="Zoom in"]');
    $("div[title|='Zoom in']").focus();
    return false;
}

//deprecated
function skip_to_links() {
    var link = $("#ycba-image-rights > a").first();
    link.focus();
    return false;
}

function copy_to_clipboard() {
    //alert(document.getElementById("caption-dl-info").textContent);
    var copyText = document.getElementById("caption-dl-info").textContent.trim();

    /* Select the text field */ /* ERJ not needed */
    //copyText.select();
    //copyText.setSelectionRange(0, 99999); /* For mobile devices */

    /* Copy the text inside the text field */
    navigator.clipboard.writeText(copyText);

    /* Alert the copied text */
    alert("Caption copied.");
}

function copy_to_clipboard_direct(doc) {
    //alert(document.getElementById("caption-dl-info").textContent);
    //var copyText = document.getElementById("caption-dl-info").textContent.trim();

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
        var copyText = cap1.join(", ") + ".";

    }
    if (recordtype=="marc") {
        var cap1 = [];
        if (doc["author_ss"] != null) { cap1.push(doc["author_ss"][0]); }
        if (doc["titles_primary_ss"] != null) { cap1.push(doc["titles_primary_ss"][0].replace(/\.$/, '')); }
        //if (download != null) { cap1.push(download[1]); }////don't display caption as of 1/23/2023
        if (doc["edition_ss"] != null) { cap1.push(doc["edition_ss"][0]); }
        if (doc["publisher_ss"] != null) { cap1.push(doc["publisher_ss"][0].replace(/\.$/, '')); }
        if (doc["credit_line_ss"] != null) {
            cap1.push(doc["credit_line_ss"][0]);
        } else {
            cap1.push("Yale Center for British Art");
        }
        var copyText = cap1.join(", ") + ".";
    }

    if (recordtype=="archival") {
        var cap1 = [];
        if (doc["creator_ss"] != null) { cap1.push(doc["creator_ss"][0]); }
        if (doc["title_ss"] != null) { cap1.push(doc["title_ss"][0]); }
        if (doc["date_ss"] != null) { cap1.push(doc["date_ss"][0]); }
        var copyText = cap1.join(", ") + ".";
    }

    if (recordtype=="artists") {
        var cap1 = [];
        cap1.push("placeholder for artists caption");
        var copyText = cap1.join(", ") + ".";
    }

    /* Select the text field */ /* ERJ not needed */
    //copyText.select();
    //copyText.setSelectionRange(0, 99999); /* For mobile devices */

    /* Copy the text inside the text field */
    navigator.clipboard.writeText(copyText);

    /* Alert the copied text */
    alert("Caption copied.");
}
//overrides
$(document).on("turbolinks:load",function() {
    //set h1 with title from head
    $("h1").text($("head title").text());

    var $item = $('.item');
    var $numberofSlides = $('.item').length;
    var $currentSlide = Math.floor((Math.random() * $numberofSlides));

    $('.carousel-indicators li').each(function(){
        var $slideValue = $(this).attr('data-slide-to');
        if($currentSlide == $slideValue) {
            $(this).addClass('active');
            $item.eq($slideValue).addClass('active');
        } else {
            $(this).removeClass('active');
            $item.eq($slideValue).removeClass('active');
        }
    });

    $('.iiifpopover').popover({
        html : true,
        content: function() {
            return $('#iiifpopover_content_wrapper').html();
        }
    });

});