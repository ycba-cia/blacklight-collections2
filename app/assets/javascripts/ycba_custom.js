function toggle_citation() {
    //console.log("test toggle_citation");
    var closed = document.getElementsByClassName("blacklight-citation_txt-closed")[0];
    var open = document.getElementsByClassName("blacklight-citation_txt-open")[0];
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

function skip_to_osd() {
    //var zoomin = document.querySelector('[title="Zoom in"]');
    $("div[title|='Zoom in']").focus();
    return false;
}

function skip_to_links() {
    var link = $("#ycba-image-rights > a").first();
    link.focus();
    return false;
}

//overrides
$(document).on("turbolinks:load",function() {
    //set h1 with title from head
    $("h1").text($("head title").text());

});