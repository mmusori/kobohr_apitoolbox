'-
***********************************************
Developed by: Punya Prasad Sapkota
Last Modified: 23 May 2018
***********************************************
#---USAGE
#--TWO Sections
#Section 1
#-----KoBo data Access using API v1
#-----https://kc.humanitarianresponse.info/api/v1
#Section 2
#-----new KoBo KPI
-'

###--------SECTION 2---KPI---------
#---Upload form in NEW KoBo toolbox--------
#Import your form first (POST to https://kobo.humanitarianresponse.info/imports/)
#which will create a new asset in KPI which you can then deploy 
#by POSTing to https://kobo.humanitarianresponse.info/assets/[asset ID number]/deployment/
#USAGE: kobo_formxlsx="./xlsform/kobo_1701_NW.xlsx"
#url = "https://kobo.humanitarianresponse.info/imports/"

#POST a new import as a multipart form. The necessary parameters are library=false and file, which cotains the XLSForm:
#john@scrappy:/tmp/api_demo$ curl --silent --user jnm_api:test-for-punya --header 'Accept: application/json' 
#-X POST https://kobo.humanitarianresponse.info/imports/ --form library=false --form file=@kobo_1701_NW.xlsx | python -m json.tool

kobohr_kpi_upload_xlsform <-function(url,kobo_form_xlsx,u,pw){
  #STEP 1 ---importing a form---
    #POST a new import as a multipart form. The necessary parameters are library=false and file, which cotains the XLSForm:
    #john@scrappy:/tmp/api_demo$ curl --silent --user jnm_api:test-for-punya --header 'Accept: application/json' 
    #-X POST https://kobo.humanitarianresponse.info/imports/ --form library=false --form file=@kobo_1701_NW.xlsx | python -m json.tool
    result<-httr::POST(url=url,
                       body=list(
                         file=upload_file(path=kobo_form_xlsx),
                         library = 'false'
                       ),
                       authenticate(u,pw)
    )
    #return asset uid
    d_content <- rawToChar(result$content)
    d_content <- fromJSON(d_content)
    #get the url to pass to the next step
    status<- d_content$status ##--success - status = 'processing'
    print (status)
    import_url<-d_content$url
    print (paste0("Asset Import URL - ",import_url))
    return(d_content) 
}

#STEP2----Get the asset UID-------------------------
#The asset UID is given by messages.created[0].uid in the JSON response when GETting an import. 
#Multiple GETs may be required until the server indicates "status": "complete" in the response:
#john@scrappy:/tmp/api_demo$ curl --silent --user jnm_api:test-for-punya --header 'Accept: application/json' 
#https://kobo.humanitarianresponse.info/imports/iGYukk6NVEA64zwMsPtgRD/ | python -m json.tool
# the URL is fetched from the output of 

kobohr_kpi_get_asset_uid<-function(url, u, pw){
  result<-GET(url=url,authenticate(u,pw),progress())
  d_content <- rawToChar(result$content)
  d_content <- fromJSON(d_content)
  #--success - status = 'complete'
  print (d_content$status)
  asset_uid <- d_content$messages$created$uid
  print (paste0("Asset UID - ", asset_uid))
  #print (paste0("Asset UID - ", asset_uid))
  return(d_content)
}

#STEP3-----Deploying an Asset------
#Deploying an asset
#Construct a URL using the asset UID: https://kobo.humanitarianresponse.info/assets/[your-asset-UID]/deployment/; 
#then, POST with the form parameter active=true.
#john@scrappy:/tmp/api_demo$ curl --silent --user jnm_api:test-for-punya --header 'Accept: application/json' 
#-X POST https://kobo.humanitarianresponse.info/assets/apLBsTJ4JAReiAWQQQBKNZ/deployment/ --form active=true | python -m json.tool

#d<-list(owner=paste0("https://kobo.humanitarianresponse.info/users/",kobo_user,"/"),active=TRUE)
#kobo_url<-""https://kobo.humanitarianresponse.info/"
kobohr_kpi_deploy_asset<- function (asset_uid, u, pw){
  asset_deployment_url <-paste0(kobo_server_url,"assets/",asset_uid,"/deployment/")
  d <- list(owner=paste0(kobo_server_url, "users/",u,"/"),active=TRUE)
  result<-httr::POST (url=asset_deployment_url,
                      body=d,
                      authenticate(u,pw)
  )
  d_content <- rawToChar(result$content)
  d_content <- fromJSON(d_content)
  print (paste0("Deployment Success - ", d_content$identifier))
  return(d_content)
}
#
# #Share asset with another user
# # Share a form
# # Sharing requires a POST to "https://kobo.humanitarianresponse.info/permissions/"
# # with three form parameters
# # content_object: the URL, relative or absolute, of the asset to be shared, e.g. /assets/aSAKqcFRv9nYWqiKGvZC7w/
# # permission: a string indicating the permission to grant, e.g. change_asset. This can be any assignable permission for an
# # asset
# # user: the URL, relative or absolute, identifying the user who will receive the new permission, e.g. /users/jnm/. The last
# # component of the URL is the username.
# # john@scrappy:/tmp/api_demo$ curl ‐‐silent ‐‐user jnm_api:test‐for‐punya ‐‐header 'Accept:
# # application/json' ‐X POST 'https://kobo.humanitarianresponse.info/permissions/' ‐‐form
# # content_object=/assets/apLBsTJ4JAReiAWQQQBKNZ/ ‐‐form permission=change_asset ‐‐form
# # user=/users/jnm/ | python ‐m json.tool
# ##SHARE AssET
# # Assignable permissions that are stored in the database
# # ASSIGNABLE_PERMISSIONS = (
# #   'view_asset',
# #   'change_asset',
# #   'add_submissions',
# #   'view_submissions',
# #   'change_submissions',
# #   'validate_submissions',
# # )
# 
# #kobo_server_url<-"https://kobo.humanitarianresponse.info/"
#
kobohr_kpi_share_asset<-function(content_object_i, permission_i, user_i, u, pw){
  asset_share_url <-paste0(kobo_server_url,"permissions/")
  d <- list(content_object=content_object_i, permission=permission_i, user=user_i)
  result<-httr::POST (url=asset_share_url,
                      body=d,
                      authenticate(u,pw)
  )
  d_content <- rawToChar(result$content)
  d_content <- fromJSON(d_content)
  return(d_content)
}

#----CREATE EXPORTS-------------------------#
#Examples to call functions
# d_exports<-kobohr_create_export(type=type,lang=lang,fields_from_all_versions=fields_from_all_versions,hierarchy_in_labels=hierarchy_in_labels,group_sep=group_sep,asset_uid=asset_uid,kobo_user,Kobo_pw)
# d_exports<-as.data.frame(d_exports)
# 
# d_latest_export<-kobohr_latest_exports(asset_uid,kobo_user,Kobo_pw)
# d_latest_export<-as.data.frame(d_latest_export)
#################-----https://github.com/tinok/kobo_api/blob/master/get_csv.py--------------#########
# ###Get asset information
# asset_uid<-"aaUR7DuXPLGsVUqMbv7BcB"
# ###define some variables
# # These variables define the default export. Each value can be overwritten when running the `create' command
# # e.g. `create xml 'English (en_US)' true'. It's possible to skip some arguments at the end but they need to be passed in the same order.
# asset_uid_<-asset_uid
# type <- "csv"
# lang <- "xml"
# fields_from_all_versions <- "true"
# hierarchy_in_labels <- "false"
# group_sep = "/"

###--CREATE EXPORT-----------
kobohr_create_export<-function(type,lang,fields_from_all_versions,hierarchy_in_labels,group_sep,asset_uid,kobo_user,Kobo_pw){
  api_url_export<-paste0(kobo_server_url,"exports/")
  api_url_asset<-paste0(kobo_server_url,"assets/",asset_uid,"/")
  api_url_export_asset<-paste0(kobo_server_url,"exports/",asset_uid,"/")
  #
  d<-list(source=api_url_asset,
          type=type,
          lang=lang,
          fields_from_all_versions=fields_from_all_versions,
          hierarchy_in_labels=hierarchy_in_labels,
          group_sep=group_sep)
  #fetch data
  result<-httr::POST (url=api_url_export,
                      body=d,
                      authenticate(kobo_user,Kobo_pw),
                      progress()
  )
  
  print(paste0("status code:",result$status_code))
  d_content <- rawToChar(result$content)
  print(d_content)
  d_content <- fromJSON(d_content)
  return(d_content)
}

###---list exports----------------###
#https://www.r-bloggers.com/using-the-httr-package-to-retrieve-data-from-apis-in-r/
kobohr_list_exports<-function(asset_uid,kobo_user,Kobo_pw){
  api_url_export<-paste0(kobo_server_url,"exports/")
  api_url_asset<-paste0(kobo_server_url,"assets/",asset_uid,"/")
  api_url_export_asset<-paste0(kobo_server_url,"exports/",asset_uid,"/")
  #
  payload<-list(q=paste0('source:',asset_uid))
  #payload<-list(source=asset_uid_)
  #fetch data
  result<-httr::GET (url=api_url_export,
                     query=payload,
                     authenticate(kobo_user,Kobo_pw),
                     progress()
  )
  
  warn_for_status(result)
  stop_for_status(result)
  
  print(paste0("status code:",result$status_code))
  #
  d_content<-fromJSON(content(result,"text",encoding = "UTF-8"))
  #get both result and data
  d_content_result<-data.frame(d_content$results$result,d_content$results$date_created,d_content$results$last_submission_time)
  #replace texts in the field name
  names(d_content_result)<-str_remove(names(d_content_result),"d_content.results.")
  d_content_data<-data.frame(d_content$results$data)
  d_content_all<-bind_cols(d_content_result,d_content_data)
  ##rename
  #names(d_content_all)<-c("result",names(d_content_data))
  #filter content by the asset uid
  d_content_list<-d_content_all %>% 
    filter(str_detect(source,asset_uid))
  #d_content_ <-as.data.frame(d_content$results$url,d_content$results$uid)
  return(d_content_list)
}


#Get the latest export URL
kobohr_latest_exports<-function(asset_uid,kobo_user,Kobo_pw){
  d_list_export_urls<-kobohr_list_exports(asset_uid,kobo_user,Kobo_pw)
  d_list_url<-d_list_export_urls[nrow(d_list_export_urls),]
  latest_url<-d_list_url$result
  return(latest_url)
}


###################--------SECTION 1---########################################
#########--------------------KC--------------------############################
#---Upload form in KoBo toolbox--------
#curl -X POST -F xls_file=@/path/to/form.xls https://kobo.humanitarianresponse.info/api/v1/forms
#POST(url, body = upload_file("mypath.txt"))
#USAGE: kobo_formxlsx="./xlsform/kobo_1701_NW.xlsx"
#url = "https://kc.humanitarianresponse.info/api/v1/forms"
# kobohr_upload_xlsform <-function(url,kobo_xlsform,u,pw){
#   result<-httr::POST (url,
#                       body=list(
#                         xls_file=upload_file(path=kobo_xlsform)),
#                       authenticate(u,pw))
#   result<-result
# }

#user names and password to be loaded from external authenticate file - this approach to be checked
#returns list of forms as a dataframe
#url <- "https://kc.humanitarianresponse.info/api/v1/data.csv"
kobohr_getforms_csv <-function(url,u,pw){
  #supply url
  rawdata<-GET(url,authenticate(u,pw),progress())
  d_content_csv <-read_csv(content(rawdata,"raw",encoding = "UTF-8"))
}

#returns the CSV content of the form
#url<-https://kc.humanitarianresponse.info/api/v1/data/145448.csv
kobohr_getdata_csv<-function(url,u,pw){
  #supply url for the data
  rawdata<-GET(url,authenticate(u,pw),progress())
  d_content <- read_csv(content(rawdata,"raw",encoding = "UTF-8"))
}

#submission count
#returns number of data submisstion in each form
#url<-'https://kc.humanitarianresponse.info/api/v1/stats/submissions/145533?group=anygroupname'
kobohr_count_submission <-function(url,u,pw){
  #supply url
  rawdata<-GET(url,authenticate(u,pw),progress())
  d_content <- rawToChar(rawdata$content)
  d_content <- fromJSON(d_content)
  d_count_submission <- d_content$count
  #check whether there is record or not
  if (is.null(d_count_subm)){
    d_count_submission <-0
  }
  return(d_count_submission)
}

#downlod data in CSV format
#---Parameters
#-----formid <- 145533
#-----savepath <- "./data/data_export_csv/"
#-----u <- "username"
#-----pw <- "password"
kobohr_download_csv<-function(formid,savepath,u,pw){
  #check the submission first
  d_count_subm<-NULL
  stat_url<- paste0(kc_server_url,"api/v1/stats/submissions/",formid,"?group=anygroup")
  d_count_subm <- kobohr_count_submission (stat_url,u,pw)
  #download data only if submission
  if (!is.null(d_count_subm)){
    #Example "https://kc.humanitarianresponse.info/api/v1/data/79489.csv"
    kobo_csv_url <- paste0(kc_server_url,"api/v1/data/", formid,".csv")
    d_rawi<-kobohr_getdata_csv(kobo_csv_url,u,pw)
    #write to csv
    #save file name
    savefile <- paste0(savepath,formid,"_data.csv")
    write_csv(d_rawi,savefile)
  }
}

#------------------------------------------------------------#
#supply url
#user names and password to be loaded from external authenticate file - this approach to be checked
kobohr_getforms <-function(url,u,pw){
  #supply url
  rawdata<-GET(url,authenticate(u,pw),progress())
  d_content <- rawToChar(rawdata$content)
  d_content <- fromJSON(d_content)
}

kobohr_getdata<-function(url,u,pw){
  #supply url for the data
  rawdata<-GET(url,authenticate(u,pw),progress())
  d_content <- rawToChar(rawdata$content)
  d_content <- fromJSON(d_content)
}













