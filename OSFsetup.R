# Loop through CSV to setup emails for OSF / SPNHC

# install.packages("tinytex")  # Need this for knitr / pdf_document

library("rmarkdown")
library("readr")
library("knitr")
library("rJava")
library("mailR")


# Prep Abstracts ####
# Import list of abstracts
SPNHCformBU <- read_csv("SPNHC2019abstracts_prep_20190306.csv")
SPNHCform <- SPNHCformBU[is.na(SPNHCformBU$`Abstract Title`) == F,]

# remove already-imported abstracts
lastnames <- c("")
SPNHCform <- SPNHCform[!SPNHCform$`Last Name` %in% lastnames,]

# check for missing & duplicate abstracts
checkMiss <- SPNHCformBU[is.na(SPNHCformBU$`Abstract Text`) == T,]
checkDups <- dplyr::count(SPNHCform, `Abstract Text`)

# strip out special chars & diacritics to form PDF filename
SPNHCform$PDFname <- gsub("[-.,/~' ]", "_", SPNHCform$`Last Name`)
SPNHCform$PDFname <- iconv(SPNHCform$PDFname, from = "UTF-8", to = 'ASCII//TRANSLIT')
# check names - may need to manually fix some if iconv can't catch all special characters

# Prep PDFs ####
# Set Rmd template for PDF
rmd_stub <- "OSFpdfTemplate.Rmd"

for (i in 1:NROW(SPNHCform)) {
  
  rmarkdown::render(rmd_stub,
                    output_format = "pdf_document",
                    output_file = paste0("output/",
                                         SPNHCform$PDFname[i], "_",
                                         "2019SPNHCabstract_", i, ".pdf"),
                    # pdf_document(toc = FALSE, latex_engine = "lualatex", "sansfont"),
                    quiet = TRUE)
  
}
