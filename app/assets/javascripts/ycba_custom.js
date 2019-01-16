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