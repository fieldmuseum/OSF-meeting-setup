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
#  OSF API rate limit (as of spring 2019):
#   = 10,000/day with token 
#   = 100/day without
#

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

# Setup OSF API token & URL
osf_pat <- Sys.getenv("OSF_PAT")
url <- "https://api.osf.io/v2/"
# node_id_test <- "j3dk2/"  
# url_test <- "https://api.test.osf.io/v2/"


# Import submission form CSV
SPNHCabsBU <- read_csv("SPNHC2019abstracts_prep_20190306.csv")

SPNHCabs <- SPNHCabsBU[is.na(SPNHCabsBU$`Abstract Title`) == F,]


# # GET all OSF project IDs
# SPNHCprojsTest <- GET("https://api.osf.io/v2/nodes/?filter[tags]=SPNHC2019")
# SPNHCprojsTXT <- jsonlite::fromJSON(content(SPNHCprojs, "text"))
# # May need to handle pagination


# For each abstract: ####

projCheckList <- list()
projStatusList <- list()
projTXTList <- list()

# projTitleID <- data.frame("title" = "", 
#                           "osf_url" = "",
#                           stringsAsFactors = F)


checkRows <- c(28, 53, 95, 106, 108, 109, 114, 131, 133, 176)


for (i in 1:NROW(SPNHCabs)) {
# for (i in checkRows[2:NROW(checkRows)]) {
# for (i in 1:3) {  
  
  # GET OSF proj data
  # node_id <- SPNHCnodesTXT$data$id[SPNHCnodesTXT$data$attributes$title == SPNHCabs$`Abstract Title`[i]]  
  # getnode <- GET(paste0(url, "nodes/", node_id))
  
  description <- "Presentation for SPNHC 2019 - https://osf.io/view/SPNHC2019"
  
  title <- gsub(" ", "%20", SPNHCabs$`Abstract Title`[i])
  getproj2 <- GET(paste0(url, 'nodes/?filter[title]=', title),
                  config = add_headers(Authorization = paste0("Bearer ", osf_pat)))
  getprojTXT <- jsonlite::fromJSON(content(getproj2, "text"))
  
  # ~ ADD Tags ####
  # pull from those listed in form CSV
  newTags <- strsplit(SPNHCabs$`Abstract Keywords (comma-separated list of at least three keywords describing your talk)`[i],
                      split = ",")  # c("talk") 
  newTags <- list(unique(gsub("^\\s+|\\s+$", "", unlist(newTags))))
  
  # remove "emailed" & "osf4m"
  
  allTags = list( # unique(
    c(if(is.na(newTags)==FALSE) {unlist(newTags)},
      # unlist(getprojTXT$data$attributes$tags),
      "SPNHC2019", 
      if (grepl("Poster", SPNHCabs$Session[i])) {"poster"} else {"talk"},
      if (is.na(SPNHCabs$Session[i])==FALSE) {
        strsplit(SPNHCabs$Session[i], split = " ")[[1]][1]
        }
      )) # )
  
  # newTags2 <- data.frame("tags" = allTags,  # c("test1", "test2", "test3"),  
  #                        "seq" = 1:NROW(allTags),  # 1:3,
  #                        stringsAsFactors = F)
  # 
  # newTags3 <- tidyr::spread(newTags2, key = seq, tags, sep = "_")
  
  # getprojTXT$data$attributes$tags <- allTags   # newTags3
  
  patchprojTXT <- list("type" = getprojTXT$data$type[1],
                       "id" = getprojTXT$data$id[1],  # "j3dk2",  # 
                       "attributes" = list())
  
  patchprojTXT$attributes <- list(# "description" = getprojTXT$data$attributes$description, # description
                                  "tags" = unlist(allTags) # ,  # getprojTXT$data$attributes$tags),
                                  # "public" = FALSE
                                  )  # = getprojTXT$data$attributes$public[1])
  
  patchprojFIN <- list("data" = patchprojTXT)
  
  patchproj <- jsonlite::toJSON(patchprojFIN,
                                pretty = TRUE, 
                                auto_unbox = TRUE)
  
  projCheck <- PATCH(url = paste0(url, "nodes/", getprojTXT$data$id, "/"),  #  "j3dk2/"),  #   
                     config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                     content_type_json(),
                     body = patchproj,
                     encode = "json")
  
  projStatusTags <- message_for_status(projCheck)
  
  projCheckTXT <- jsonlite::fromJSON(content(projCheck, "text"))
  
  
  projCheckList[i] <- projCheck
  projStatusList[i] <- projStatusTags
  projTXTList[i] <- projCheckTXT
  
  # if (is.na(projCheck$url)==FALSE) {
  #   projTitleID$title[i] <- SPNHCabs$`Abstract Title`[i]
  #   projTitleID$osf_url[i] <- projCheck$url
  # }
  
  print(i)
  
  Sys.sleep(5)
  
}


reviewProjList <- projCheckList
reviewProjStatus <- projStatusList
reviewProjIDs <- projTitleID

# SPNHCabs2 <- SPNHCabs
SPNHCabs$osf_url <- ""
for (i in 1:NROW(SPNHCabs)){
  SPNHCabs$osf_url[i] <- unlist(projCheckList[[i]])
}
SPNHCabs$osf_node_id <- gsub("https://api.osf.io/v2/nodes|/", "", SPNHCabs$osf_url)

checkRows <- c(28, 53, 95, 106, 108, 109, 114, 131, 133, 176)
SPNHCcheck <- SPNHCabs2[checkRows,]


# write_csv(SPNHCabs2, path = "SPNHC_OSF.csv", na = "")

SPNHCabs$osf_user_id <- ""
checkUsers <- list()


# add OSF user id's to SPNHC dataset ####
# NOTE:
#   This step needs manual checks to verify matches between people/OSF-id's

for (i in 1:NROW(SPNHCabs)) {

  getuserIDs <- GET(paste0(url, '/users/?filter[family_name]=', SPNHCabs$`Last Name`[i],
                           '&filter[given_name]=', SPNHCabs$`First Name`[i]))
  getuserIDTXT <- jsonlite::fromJSON(content(getuserIDs, "text"))
  
  if (NROW(getuserIDTXT$data) < 1) {
    SPNHCabs$osf_user_id[i] <- "no match"
  } else {
    SPNHCabs$osf_user_id[i] <- getuserIDTXT$data
  }
  
  checkUsers[i] <- getuserIDTXT$meta
  
  print(i)
  
  Sys.sleep(5)
  
}


# list SPNHC admins' OSF user IDs:
user_ids <- c("xhyj8", "daem9", "js6kf", "gk3bt", "xencv")


# add SPNHC admins to OSF projs ####
for (i in 19:NROW(SPNHCabs)) {  # 1:10) {  # 
    
  getusers <- GET(paste0(url, 'nodes/',
                         # "xqjrg",
                         SPNHCabs$osf_node_id[i], 
                         "/contributors/"),
                  config = add_headers(Authorization = paste0("Bearer ", osf_pat)))
  getusersTXT <- jsonlite::fromJSON(content(getusers, "text"))

  
 # for (j in 1:NROW(user_ids)) {
    
    patchuserTXT <- list("type" = "contributors",
                         "attributes" = list("bibliographic" = "TRUE",
                                             "permission" = "admin"),
                         "relationships" = list("user" = list("data" = list("type" = "users",
                                                                            "id" = user_ids[5] # [j]
                                                                            ))))  # "xhyj8"))))
    
    
    patchuserFIN <- list("data" = patchuserTXT)
    
    patchuser <- jsonlite::toJSON(patchuserFIN,
                                  pretty = TRUE, 
                                  auto_unbox = TRUE)
    
    projCheck <- POST(url = paste0(url, "nodes/", SPNHCabs$osf_node_id[i], "/contributors/"),  #  "j3dk2/"),  #   
                      config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                      content_type_json(),
                      body = patchuser,
                      encode = "json")
    
    userStatusTags <- message_for_status(projCheck)
    
    userCheckTXT <- jsonlite::fromJSON(content(projCheck, "text"))
    
    
    # if (is.na(projCheck$url)==FALSE) {
    #   projTitleID$title[i] <- SPNHCabs$`Abstract Title`[i]
    #   projTitleID$osf_url[i] <- projCheck$url
    # }
    
    print(i)
    
    Sys.sleep(4)
    
 # }
  
}


# remove admins as bibliographic contributor
for (i in 1:NROW(SPNHCabs)) {
  
  for (j in 1:NROW(user_ids)) {
    
    patchkewTXT <- list("type" = "contributors",
                        "attributes" = list("bibliographic" = "FALSE",
                                            "permission" = "admin"),
                        "relationships" = list("user" = list("data" = list("type" = "users",
                                                                           "id" = user_ids[j]  # "js6kf"
                                                                           ))))
    patchkewFIN <- list("data" = patchkewTXT)
    
    patchkew <- jsonlite::toJSON(patchkewFIN,
                                 pretty = TRUE, 
                                 auto_unbox = TRUE)
    
    projCheck <- POST(url = paste0(url, "nodes/", SPNHCabs$osf_node_id[i], "/contributors/"),  #  "j3dk2/"),  #   
                      config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                      content_type_json(),
                      body = patchkew,
                      encode = "json")
    
    projStatusTags <- message_for_status(projCheck)
    
    projCheckTXT <- jsonlite::fromJSON(content(projCheck, "text"))
  
  }

}

SPNHCusersOSF <- list()
  
# ~ ADD Contributors ####
for (i in 1:NROW(SPNHCabs)) {
  # GET OSF user IDs
  SPNHCusers <- GET(paste0("https://api.osf.io/v2/users/?filter[family_name]=", SPNHCabs$`Last Name`[i]))
  
  SPNHCusersStat <- message_for_status(SPNHCusers)
  
  SPNHCusersTXT <- jsonlite::fromJSON(content(SPNHCusers, "text"))
  
  if (NROW(SPNHCusersTXT$data)==1) {
    SPNHCusersOSF[i] <- SPNHCusersTXT
  }
  
  # Update Contributors in project
  
}  
