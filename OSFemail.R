# Loop through CSV to submit emails for OSF / SPNHC

# install.packages("tinytex")  # Need this for knitr / pdf_document

library("rmarkdown")
library("readr")
library("knitr")
library("rJava")
library("mailR")

# Prep EMails ####
# ...to loop thru sending emails:
#    + subject = abstract title
#    + attachment = PDF of title/author/abstract
#    + body = abstract text

sender <- Sys.getenv("SENDER")
recipients <- c(Sys.getenv("RECIP1"), Sys.getenv("RECIP2"))
password <- Sys.getenv("SENDPW")


for (i in 1:NROW(SPNHCform)) {

  # Need to "allow less secure apps" - https://myaccount.google.com/lesssecureapps
  
  send.mail(from = sender,
            to = recipients,
            subject = SPNHCform$`Abstract Title`[i],
            body = SPNHCform$`Abstract Text`[i],
            encoding = "utf-8",
            smtp = list(host.name = "smtp.gmail.com",  # "aspmx.l.google.com",  # 
                        user.name = sender,
                        passwd = password,
                        ssl = T,  # tls = T, # 
                        port = 465), # 25),
            authenticate = TRUE,
            send = TRUE,
            attach.files = c(paste0("./output/",
                                    SPNHCform$PDFname[i], "_",
                                    "2019SPNHCabstract_", i, ".pdf")),
            file.descriptions = c("Abstract PDF"), # optional parameter
            debug = TRUE)
  
  print(i)
  
  Sys.sleep(10)

}
