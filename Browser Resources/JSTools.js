function MyAppGetHTMLElementsAtPoint(x,y) {
    var tags = ",";
    var url = "";
    var pat = /^https?:\/\//i;
    var pat2 = /^\/\//i
    var e = document.elementFromPoint(x,y);
    while (e) {
        if (e.tagName) {
            tags += e.tagName + ',';
            if (e.tagName == 'A') {
                url = e.getAttribute('href');
                if (url.match(pat)) {
                    //noop
                } else if (url.match(pat2)) {
                    url = window.location.protocol + url;
                } else {
                    url = window.location.protocol + '//' + window.location.hostname + url;
                }
            } else if (e.tagName == 'IMG') {
                url = e.getAttribute('src');
                if (url.match(pat)) {
                    //noop
                } else if (url.match(pat2)) {
                    url = window.location.protocol + url;
                } else {
                    url = window.location.protocol + '//' + window.location.hostname + url;
                }
            }
        }
        e = e.parentNode;
    }
    return tags + '|' + url;
}