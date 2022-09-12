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