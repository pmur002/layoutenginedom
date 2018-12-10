
## CSS standard says 1px = 1/96in !?
dpi <- 96

DOMLayout <- function(html, width, height, fonts, device) {
    ## Work in temp directory
    wd <- file.path(tempdir(), "layoutEngineDOM")
    if (!dir.exists(wd)) {
        result <- dir.create(wd, showWarnings=TRUE)
        if (!result) stop("Creation of working directory failed")
    }
    assetDir <- file.path(wd, "assets")
    if (!dir.exists(assetDir)) {
        result <- dir.create(assetDir, showWarnings=TRUE)    
        if (!result) stop("Creation of working directory failed")
    }
    ## Copy font files
    fontFiles <- fontFiles(fonts, device)
    file.copy(fontFiles, assetDir)
    ## Convert any .pfb/.pfa to .ttf
    pffiles <- grepl("[.]pf[ab]$", fontFiles)
    if (any(pffiles)) {
        fontforge <- Sys.which("fontforge")
        if (nchar(fontforge) == 0) stop("FontForge not available")
        for (i in fontFiles[pffiles]) {
            system(paste0(fontforge,
                          " -lang=ff -script ",
                          system.file("FF", "pf2ttf",
                                      package="layoutEngineDOM"),
                          " ", file.path(assetDir, basename(i))))
        }
    }
    ## Copy any assets
    copyAssets(html, assetDir)
    ## Append layout calculation code
    file.copy(system.file("JS", "font-baseline", "index.js",
                          package="layoutEngineDOM"),
              assetDir)
    file.copy(system.file("JS", "layout.js", package="layoutEngineDOM"),
              assetDir)
    body <- xml_find_first(html$doc, "body")
    xml_add_child(body, "script", src="assets/index.js")
    xml_add_child(body, "script", src="assets/layout.js")
    ## Open DOM page with <body> and <style> in <head>
    HTML <- as.character(xml_children(body))
    style <- xml_find_all(html$doc, "head/style")
    ## Establish R http server root
    oldwd <- getwd()
    if (!is.null(oldwd))
        on.exit(setwd(oldwd))
    setwd(wd)
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
    names(layoutDF) <- names(layoutFields)
    ## Convert font size from CSS pixels to points
    layoutDF$size <- layoutDF$size*72/dpi
    do.call(makeLayout, layoutDF)
}

DOMfontFile <- function(file) {
    ## Strictly, @font-face spec does not allow .pfb/.pfa
    ## Replace .pfb/.pfa with .ttf
    ## (the conversion of the actual font happens in the layout function)
    gsub("[.]pf[ab]$", ".ttf", file)
}

DOMEngine <- makeEngine(DOMLayout,
                        cssTransform=list(fontFile=DOMfontFile))
