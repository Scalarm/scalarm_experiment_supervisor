setGeneric("schedule_point", function(.Object, params) {
  .Object
})
setGeneric("get_result", function(.Object, params) {
  .Object
})
setGeneric("mark_as_complete", function(.Object, result) {
  .Object
})
Scalarm = setClass("Scalarm", # TODO parameters_ids changes
                   slots=list(
                     user="character",
                     password="character",
                     experiment_id ="character",
                     address="character",
                     parameters_ids="vector",
                     http_schema ="character",
                     verify ="logical"
                   ))

setMethod("initialize", "Scalarm", function(.Object, user, password,experiment_id,address,parameters_ids,http_schema,verify) {
  .Object@user = user
  .Object@password = password
  .Object@experiment_id = experiment_id
  .Object@address = address
  .Object@parameters_ids =parameters_ids
  .Object@http_schema =http_schema
  .Object@verify =verify
  .Object
})


setMethod("schedule_point", "Scalarm", function(.Object, params) { #TODO better URL handling
  point=structure(list(params),.Names="point")
  url <- paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/schedule_point.json",sep="")
  encoded_url <- URLencode(toJSON(params))
  modified_url<- paste(url,"?point=",encoded_url, sep="")
  library(RCurl) #
  r=POST(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost=0,ssl_verifypeer=0) )
  print("Scheduling point")
  print(toJSON(r$params))
  r
})



setMethod("get_result", "Scalarm", function(.Object, params){
  while(1){
    url <- paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/get_result.json",sep="")
    encoded_url <- URLencode(toJSON(params))
    modified_url<- paste(url,"?point=",encoded_url, sep="")
    library(RCurl)
    r = GET(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost=0,ssl_verifypeer=0) ) # how to check verification of SSl
      content = rawToChar(r$content)
      results = fromJSON(content)
    if (results$status=="error") {
      print("Status: error; Waiting for results")
      Sys.sleep(1)
    }
    else{
      print("Point returned")
      print(toJSON(results$result))
      return(results$result)
    }
  }
})


setMethod("mark_as_complete", "Scalarm", function(.Object, result) {
  url <- paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/mark_as_complete.json",sep="")
  encoded_url <- URLencode(result)
  modified_url<- paste(url,"?results=",encoded_url, sep="")
  print(modified_url)
  library(RCurl) #
  r=POST(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost=0,ssl_verifypeer=0) )
  print( "Marked as complete and sent")
  print(result)
})


