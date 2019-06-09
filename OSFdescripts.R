# update descriptions in OSF projects

# OSF / SPNHC 2019

library("httr")
library("osfr")
library("readr")
library("jsonlite")

# Setup Notes: ####
# 
#  In .Renviron, add this line:
#   OSF_PAT = "[OSF token]"
# 
#  API rate limit:
#   = 10,000/day with token 
#   = 100/day without
#

# Setup OSF API token & URL
osf_pat <- Sys.getenv("OSF_PAT")
url <- "https://api.osf.io/v2/"
node_id_test <- "j3dk2/"  
# url_test <- "https://api.test.osf.io/v2/"


# Import submission form CSV
oldSPNHCabsBU <- read_csv("SPNHC2019abstracts_prep_20190319.csv")
SPNHCabsBU <- read_csv("SPNHC2019abstracts_prep_20190329.csv")

# SPNHCabs <- SPNHCabsBU[is.na(SPNHCabsBU$`Abstract Title`) == F,]
SPNHCabs <- SPNHCabsBU[grepl("done", tolower(SPNHCabsBU$divvy)),]

SPNHCabs$osf_node_id <- gsub("https://osf.io/", "", SPNHCabs$osf_url)
SPNHCabs$osf_node_id <- gsub("/", "", SPNHCabs$osf_node_id)


# For each abstract: ####
projCheckList <- list()
projStatusList <- list()
projTXTList <- list()

print(Sys.time())

for (i in 2:NROW(SPNHCabs)) {

  # Add OSF SPNHC metg URL to abstract descriptions
  # description <- "Part of SPNHC 2019 | https://osf.io/view/SPNHC2019"
  
  patchprojTXT <- list("type" = "nodes",
                       "id" = SPNHCabs$osf_node_id[i],  # "j3dk2",  #
                       "attributes" = list( # "description" = description,
                                           "public" = TRUE)
                       )
  
  patchprojFIN <- list("data" = patchprojTXT)
  
  patchproj <- jsonlite::toJSON(patchprojFIN,
                                pretty = TRUE, 
                                auto_unbox = TRUE)
  
  projCheck <- PATCH(url = paste0(url, "nodes/", SPNHCabs$osf_node_id[i], "/"),  # j3dk2/"),  #  
                     config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                     content_type_json(),
                     body = patchproj,
                     encode = "json")
  
  projStatusTags <- message_for_status(projCheck)
  
  projCheckTXT <- jsonlite::fromJSON(content(projCheck, "text"))
  
  
  # projCheckList[i] <- projCheck
  # projStatusList[i] <- projStatusTags
  # projTXTList[i] <- projCheckTXT

  print(i)
  
  Sys.sleep(1)
  
}


print(Sys.time())

# Get node attributes (titles + url + description) 
#   (get contributors later)

nodes_info <- list(list(list(), list()))
googleCheck <- data.frame("osf_url" = "",
                          "title" = "",
                          "descrip_check" = "",
                          stringsAsFactors = F)

print(Sys.time())

for (i in 2:NROW(SPNHCabs)) {

  # GET OSF proj data
  getnode <- GET(paste0(url, "nodes/", SPNHCabs$osf_node_id[i]))
  
  getnodeTXT <- jsonlite::fromJSON(content(getnode, "text"))
  
  nodes_info[i][[1]] <- getnodeTXT
  
  projStatusTags <- message_for_status(getnode)
  
  googleCheck[i,] <- c("osf_node_id" = SPNHCabs$osf_node_id[i],
                       "title" = getnodeTXT$data$attributes$title,
                       "descrip_check" = getnodeTXT$data$attributes$description)
  
  print(i)
  
  Sys.sleep(3)

}

print(Sys.time())

googleUpdate <- merge(SPNHCabs, googleCheck,
                      by = "osf_node_id",
                      all = TRUE)

googleUpdate$titleCheck <- "yes"
googleUpdate$titleCheck[tolower(googleUpdate$title) != tolower(googleUpdate$`Abstract Title`)] <- "no"

write_csv(googleUpdate, path = paste0("googleUpdate",Sys.Date(),".csv"))

