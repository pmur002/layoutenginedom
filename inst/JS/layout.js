
// Use element 'id' if that exists, 
// otherwise, element tag name plus child index
function elementName(node, index, parentName) {
    var tagName = node.nodeName;
    var id = node.getAttribute("id");
    if (id != null) {
        return parentName + "." + tagName + "." + id;
    } else {
        return parentName + "." + tagName + "." + index;
    }
}

function textName(index, parentName) {
    return parentName + ".TEXT." + index;
}

function borderWidth(style, border) {
    return style[border].replace("px", "");
}

function hexColor(rgb) {
    var pieces = rgb.split(/[,()]/);
    var red = Number(pieces[1]).toString(16);
    if (red.length < 2) red = "0" + red;
    var green = Number(pieces[2]).toString(16);
    if (green.length < 2) green = "0" + green;
    var blue = Number(pieces[3]).toString(16);
    if (blue.length < 2) blue = "0" + blue;
    var alpha = "FF";
    if (pieces.length > 5) {
        alpha = Number(pieces[4]).toString(16);
        if (alpha.length < 2) alpha = "0" + alpha;
    }
    return "#" + red + blue + green + alpha;
}

// Add <span/> wrapper on any text that is not ALL white space
// and is not already wrapped within a <span/>
// The algorithm is to find ALL text nodes then, for each, if
// there is no ancestor that is a <span/>, then wrap in a <span/>
function getTextNodes(parent) {
    var textNodes = [];
    for (parent = parent.firstChild; parent; parent = parent.nextSibling) {
	if (['SCRIPT','STYLE'].indexOf(parent.tagName) >= 0) 
            continue;
	if (parent.nodeType === Node.TEXT_NODE) 
            textNodes.push(parent);
	else 
            textNodes = textNodes.concat(getTextNodes(parent));
    }
    return textNodes;
}

function emptyText(node) {
    return node.nodeValue.match(/^\s*$/);
}

function split(node) {
    return node.nodeValue.split(/\s/);
}

function spanifyText() {
    var text = getTextNodes(document.body);
    var parent, span, overallspan;
    var i, j;
    for (i = 0; i < text.length; i++) {
	var words = split(text[i]);
        if (!emptyText(text[i]) && words.length > 1) {
            parent = text[i].parentNode;
	    overallspan = document.createElement("span");
            for (j = 0; j < words.length; j++) {
                span = document.createElement("span");
                span.appendChild(document.createTextNode(words[j] + " "));
                overallspan.appendChild(span);
     	    }
            parent.replaceChild(overallspan, text[i]);
        }
    }
}

function writeBox(node, index, parentName) {
    var line = "";
    if (node.nodeType == Node.ELEMENT_NODE &&
        // Ignore some elements
        node.nodeName.toUpperCase() != "SCRIPT" &&
        node.nodeName.toUpperCase() != "STYLE") {
        line = line + node.nodeName + ",";
        var elName = elementName(node, index, parentName);
        line = line + elName + ",";
        var bbox = node.getBoundingClientRect();
        line = line + bbox.left + ",";
        line = line + bbox.top + ",";
        line = line + bbox.width + ",";
        line = line + bbox.height + ",";
        // No text information (text, family, bold, italic, size, color)
        line = line + "NA,NA,NA,NA,NA,NA" + ",";
        var style = window.getComputedStyle(node);
        line = line + hexColor(style["background-color"]) + ",";
        // Borders
        line = line + borderWidth(style, "border-left-width") + ",";
        line = line + borderWidth(style, "border-top-width") + ",";
        line = line + borderWidth(style, "border-right-width") + ",";
        line = line + borderWidth(style, "border-bottom-width") + ",";
        line = line + style["border-left-style"] + ",";
        line = line + style["border-top-style"] + ",";
        line = line + style["border-right-style"] + ",";
        line = line + style["border-bottom-style"] + ",";
        line = line + hexColor(style["border-left-color"]) + ",";
        line = line + hexColor(style["border-top-color"]) + ",";
        line = line + hexColor(style["border-right-color"]) + ",";
        line = line + hexColor(style["border-bottom-color"]);
        line = line + "\n";
        // console.log(line);
        var i;
        var children = node.childNodes;
        for (i=0; i<children.length; i++) {
            line = line + writeBox(children[i], i + 1, elName);
        }
    } else if (node.nodeType == Node.TEXT_NODE &&
               !/^\s*$/.test(node.nodeValue)) {
        line = line + "TEXT,";
        line = line + textName(index, parentName) + ",";
        var parent = node.parentElement;
        var bbox = parent.getBoundingClientRect();
        line = line + bbox.left + ",";
        line = line + bbox.top + ",";
        line = line + bbox.width + ",";
        line = line + bbox.height + ",";
        // Text 
        line = line + "'" + node.nodeValue + "'" + ",";
        var style = window.getComputedStyle(parent);
        line = line + style["font-family"] + ",";
        line = line + ((style["font-weight"] == "bold" ||
                        style["font-weight"] > 500)?"TRUE":"FALSE") + ",";
        line = line + ((style["font-style"] != "normal")?"TRUE":"FALSE") + ",";
        line = line + style["font-size"].replace("px", "") + ",";
        line = line + hexColor(style["color"]) + ",";
        // No background
        line = line + "NA,";
        // No border properties (width, style, color)
        line = line + "NA,NA,NA,NA,";
        line = line + "NA,NA,NA,NA,";
        line = line + "NA,NA,NA,NA";
        line = line + "\n";
    } else {
        // just a comment;  do nothing
        // console.log("skipping type " + node.nodeType + " node ...");
    }
    return line;
}

function calculateLayout() {
    spanifyText();
    var body = document.body;
    var csv = "BODY,BODY.1," + 0 + "," + 0 + "," + 
        body.offsetWidth + "," + body.offsetHeight + "\n";
    var i;
    var children = body.childNodes;
    for (i=0; i<children.length; i++) {
        csv = csv + writeBox(children[i], i + 1, "BODY.1");
    }
    // Place result in hidden DIV
    var result = document.createElement("div");
    result.innerHTML = csv;
    result.style.display = "none";
    result.id = "layoutEngineDOMresult";
    body.appendChild(result);
}
