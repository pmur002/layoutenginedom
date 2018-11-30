
## CSS standard says 1px = 1/96in !?
dpi <- 96

DOMLayout <- function(html, width, height, fonts, device) {
    ## Work in temp directory
    wd <- file.path(tempdir(), "layoutEngineDOM")
    if (!dir.exists(wd))
        dir.create(wd)
    assetDir <- file.path(wd, "assets")
    if (!dir.exists(assetDir))
        dir.create(assetDir)    
    oldwd <- setwd(wd)
    on.exit(setwd(oldwd))
    ## Copy font files
    file.copy(fontFiles(fonts, device), assetDir)
    ## Copy any assets
    copyAssets(html, assetDir)
    ## Append layout calculation code
    file.copy(system.file("JS", "layout.js", package="layoutEngineDOM"),
              assetDir)
    body <- xml_find_first(html, "body")
    xml_add_child(body, "script", src="assets/layout.js")
    ## Open DOM page with <body> and <style> in <head>
    HTML <- as.character(xml_children(body))
    style <- xml_find_first(html, "head/style")
    page <- htmlPage(HTML, head=as.character(style))
    ## Add script to calculate the page layout
    appendChild(page, javascript("calculateLayout()"), css("body"))
    ## Get the layout info back
    layoutDIV <- getElementById(page, "layoutEngineDOMresult")    
    ## Keep checking in case it is taking a while to calculate
    ## (but give up after 5 secs)
    now <- Sys.time()
    while (length(layoutDIV) == 0 &&
           Sys.time() - now < 5) {
        layoutDIV <- getElementById(page, "layoutEngineDOMresult")
    }
    if (length(layoutDIV) == 0) {
        stop("layout calculation timed out")
    } 
    layoutCSV <- getProperty(page, css("div#layoutEngineDOMresult"),
                             "innerHTML")
    closePage(page)
    layoutDF <- read.csv(textConnection(layoutCSV),
                         header=FALSE, stringsAsFactors=FALSE,
                         quote="'\"")
    ## Convert font size from CSS pixels to points
    layoutDF[, 11] <- layoutDF[, 11]*72/dpi
    do.call(makeLayout, unname(layoutDF))
}

DOMEngine <- makeEngine(DOMLayout)
