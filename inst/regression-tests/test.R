
library(layoutEngineDOM)
library(gyre)
library(xtable)

## Use phantomClient for testing because that is better for automation
## (no GUIs popping up all over the place)
## This is not a sensible way to use layoutEngineDOM in practice
## because it offers nothing over layoutEnginePhantomJS,
## but it is reasonable for automated testing
## NOTE that for remote automated testing, might need
## QT_QPA_PLATFORM="offscreen" so PhantomJS does not look for an X server
options(DOM.client=DOM::phantomClient,
        DOM.width=600)

tests <- function() {
    grid.html("<p>test</p>")
    grid.newpage()
    grid.html(xtable(head(mtcars[1:3])), 
              x=unit(1, "npc") - unit(2, "mm"),
              y=unit(1, "npc") - unit(2, "mm"),
              just=c("right", "top"))
    grid.newpage()
    grid.html('<p style="width: 100px; border-width: 1px">This paragraph should split a line</p>')    
}

pdf("tests.pdf")
tests()
dev.off()

cairo_pdf("tests-cairo.pdf", onefile=TRUE)
tests()
dev.off()

## Check graphical output
testoutput <- function(basename) {
    PDF <- paste0(basename, ".pdf")
    savedPDF <- system.file("regression-tests", paste0(basename, ".save.pdf"),
                            package="layoutEngineDOM")
    diff <- tools::Rdiff(PDF, savedPDF)
    
    if (diff != 0L) {
        ## If differences found, generate images of the differences
        ## and error out
        system(paste0("pdfseparate ", PDF, " test-pages-%d.pdf"))
        system(paste0("pdfseparate ", savedPDF, " model-pages-%d.pdf"))
        modelFiles <- list.files(pattern="model-pages-.*")
        N <- length(modelFiles)
        for (i in 1:N) {
            system(paste0("compare model-pages-", i, ".pdf ",
                          "test-pages-", i, ".pdf ",
                          "diff-pages-", i, ".png"))
        } 
        stop("Regression testing detected differences")
    }
}

testoutput("tests")
testoutput("tests-cairo")
