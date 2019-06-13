# Retrieve OSF titles & abstract/wiki

library("httr")
library("osfr")
library("readr")

OSFcsv <- read_csv("OSFnodesDone.csv")

url <- "https://api.osf.io/v2/"

OSFlist <- data.frame("title" = rep("",NROW(OSFcsv)),
                      "abstract" =  rep("",NROW(OSFcsv)),
                      "nodeURL" =  rep("",NROW(OSFcsv)),
                      stringsAsFactors = F)


for (i in 1:NROW(OSFcsv)) {

  
  # get node & title 
  getnode <- GET(paste0(url, "nodes/", OSFcsv$nodeID[i]))
  
  getnodeTXT <- jsonlite::fromJSON(content(getnode, "text"))
  
  OSFlist$title[i] <- getnodeTXT$data$attributes$title
  OSFlist$nodeURL[i] <- OSFcsv$osf_url[i]
  
  print(paste(i, "- title"))
  Sys.sleep(1)
  
  
  # get wiki
  getwiki <-  GET(paste0(url, "nodes/", OSFcsv$nodeID[i], "/wikis/"))
  
  getwikiTXT <- jsonlite::fromJSON(content(getwiki, "text"))
  
  getabs <- GET(paste0(url, "wikis", getwikiTXT$data$attributes$path, "/content/"))
  
  # check for errors here
  OSFlist$abstract[i] <- content(getabs, "text", encoding = "UTF-8")
  
  print(paste(i, "- abstract"))
  Sys.sleep(2)
  
}


OSForder <- read_csv("osfOrderMerge.csv")

OSFmerged <- merge(OSForder, OSFlist,
                   by.x = "osf_url", by.y = "nodeURL",
                   all.x = T)

OSFmerged$cleanAbstract <- gsub("\\r+", "\n", OSFmerged$abstract)
OSFmerged$cleanAbstract <- gsub("\\n+\\s+\\n+", "\n", OSFmerged$cleanAbstract)
OSFmerged$cleanAbstract <- gsub("\\n+", "\n", OSFmerged$cleanAbstract)

write.csv(OSFmerged, file = paste0("OSFabs-merged-", Sys.Date(), ".csv"),
          fileEncoding = "UTF-8",
          na = "")
