# remove SPNHC admins (user_ids) from bibliographic contributors

library("httr")
library("readr")
library("jsonlite")
# library("osfr")

# Setup OSF API token & URL
osf_pat <- Sys.getenv("OSF_PAT")
url <- "https://api.osf.io/v2/"

# Setup logs
authStatusTags <- list("k" = list())
authCheckTXT <-  list("k" = list())
admStatusTags <- list("j" = list())
admCheckTXT <- list("j" = list())


# Import list of abstracts
oldSPNHCabsBU <- read_csv("SPNHC2019abstracts_prep_20190319.csv")
SPNHCabsBU <- read_csv("SPNHC2019abstracts_prep_20190329.csv")


# exclude abstracts where admin = author
#  [manually update their abstract pages]
admin_email <- c("admin1@email.com",
                 "admin2@email.com")

SPNHCabs <- SPNHCabsBU[grepl("done", tolower(SPNHCabsBU$divvy)),]
SPNHCabs <- SPNHCabs[!SPNHCabs$`Email Address` %in% admin_email,]

SPNHCabs$osf_node_id <- gsub("https://osf.io/", "", SPNHCabs$osf_url)
SPNHCabs$osf_node_id <- gsub("/", "", SPNHCabs$osf_node_id)

# setup SPNHC admin user OSF id's
user_ids <- c("xhyj8",
              "daem9",
              "js6kf",
              "gk3bt",
              "xencv")

SPNHCabs$osf_auth_id <- ""

for (i in 4:NROW(SPNHCabs)) {
  
  Sys.sleep(2)
  
  print(i)
  
  # retrieve users for a given node
  getusers <- GET(paste0(url, 'nodes/',
                         # "xqjrg",
                         SPNHCabs$osf_node_id[i], 
                         "/contributors/"),
                  config = add_headers(Authorization = paste0("Bearer ", osf_pat)))
  getusersTXT <- jsonlite::fromJSON(content(getusers, "text"))
  
  node_ids <- paste0(SPNHCabs$osf_node_id[i], "-", user_ids)
  node_contribs <- getusersTXT$data$id # getusersTXT$data$embeds$users$data$id
  
  node_author <- node_contribs[!node_contribs %in% node_ids]
  node_author_url <- gsub(paste0(SPNHCabs$osf_node_id[i], "-"), "", node_author)
  
  # # safer to manually update this:
  # if (SPNHCabs$`Email Address`[i] == "admin1@email.com") {
  #   
  #   SPNHCabs$osf_auth_id[i] == user_ids[1]
  #   
  # } else {
    
    SPNHCabs$osf_auth_id[i] <- node_author 
    
  # }

  # set author as admin ####  
  if(!is.na(node_author[1])) {
    
    for (k in 1:NROW(node_author)) {
      
      patchAuthTXT <- list("type" = "contributors",
                           "attributes" = list("permission" = "admin"),
                           "relationships" = list("user" = list("data" = list("type" = "users",
                                                                              "id" = node_author[k]  # "js6kf" #
                           ))))
      
      patchAuthFIN <- list("data" = patchAuthTXT)
      
      patchAuth <- jsonlite::toJSON(patchAuthFIN,
                                    pretty = TRUE, 
                                    auto_unbox = TRUE)
      
      authCheck <- PATCH(url = paste0(url, "nodes/", SPNHCabs$osf_node_id[i],
                                      "/contributors/", node_author_url[k], "/"),  #  "j3dk2/"),  #   
                         config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                         content_type_json(),
                         body = patchAuth,
                         encode = "json")
      
      authStatusTags <- message_for_status(authCheck)
      
      authCheckTXT <- jsonlite::fromJSON(content(authCheck, "text"))
      
      Sys.sleep(1)
      
    }
    
  }
}



for (i in 2:NROW(SPNHCabs)) {
  
  # # set SPNHC as non-biblio ####
  # for (j in 2:NROW(user_ids)) {
    
    # if (!(SPNHCabs$`Email Address`[i] == "pmayer@fieldmuseum.org" &
    #       user_ids[j] == "xhyj8")) {
      
  
      node_ids <- paste0(SPNHCabs$osf_node_id[i], "-", user_ids)
  
      patchadmTXT <- list("type" = "contributors",
                          "attributes" = list("bibliographic" = FALSE),
                          "relationships" = list("user" = list("data" = list("type" = "users",
                                                                             "id" = node_ids[1] # node_ids[j]  # "js6kf" #
                          ))))
      patchadmFIN <- list("data" = patchadmTXT)
      
      patchadm <- jsonlite::toJSON(patchadmFIN,
                                   pretty = TRUE, 
                                   auto_unbox = TRUE)
      
      admCheck <- PATCH(url = paste0(url, "nodes/", SPNHCabs$osf_node_id[i], 
                                     "/contributors/", user_ids[1], "/"),  #  user_ids[j], "/"),  # "j3dk2/"), #
                        config = add_headers(Authorization = paste0("Bearer ", osf_pat)),
                        content_type_json(),
                        body = patchadm,
                        encode = "json")
      
      admStatusTags <- message_for_status(admCheck)
      
      admCheckTXT <- jsonlite::fromJSON(content(admCheck, "text"))
      
      Sys.sleep(1)
      
#    }
    
#  }
  
}
