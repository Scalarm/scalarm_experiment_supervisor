setGeneric("check_repetitions", function(.Object, params) {})
setGeneric("schedule_point", function(.Object, params) {})
setGeneric("get_result", function(.Object, params) {})
setGeneric("mark_as_complete", function(.Object, result) {})

Scalarm = setClass("Scalarm",
                   slots = list(
                      user = "character",
                      password = "character",
                      experiment_id = "character",
                      address = "character",
                      parameters_ids = "vector",
                      http_schema = "character",
                      verify = "logical")
                  )

setMethod("initialize", "Scalarm", function(.Object, user, password,experiment_id,address,parameters_ids,http_schema,verify) {
  .Object@user = user
  .Object@password = password
  .Object@experiment_id = experiment_id
  .Object@address = address
  .Object@parameters_ids = parameters_ids
  .Object@http_schema = http_schema
  .Object@verify = verify
  .Object
  })


setMethod ("check_repetitions", "Scalarm",function(.Object, params){
    url =  paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/get_result.json",sep = "")
    encoded_url =  URLencode(toJSON(params))
    modified_url=  paste(url,"?point=",encoded_url, sep = "")
    r = GET(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost = 0,ssl_verifypeer = 0) )
    content = rawToChar(r$content)
    results = fromJSON(content)
    if (results$status == "error") {
      return(NULL)
    }
    else {
      print("Point had been scheduled already")
      print(toJSON(results$result))
      return(results$result)
    }
  })

setMethod("schedule_point", "Scalarm", function(.Object, params) {
  point = structure(list(params),.Names = "point")
  url =  paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/schedule_point.json",sep = "")
  encoded_url =  URLencode(toJSON(params))
  modified_url=  paste(url,"?point=",encoded_url, sep = "")
  r = POST(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost = 0,ssl_verifypeer = 0) )
  print("Scheduling point")
  print(toJSON(params))
  r
})



setMethod("get_result", "Scalarm", function(.Object, params){
  writing_counter = 0
  while(1){
    if(writing_counter == 20){ #After first 10 messages, their will appear in logs 10 times less frequent
      writing_counter = 9
      }
    else{
      writing_counter = writing_counter+1
      }
    url =  paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/get_result.json",sep = "")
    encoded_url =  URLencode(toJSON(params))
    modified_url=  paste(url,"?point=",encoded_url, sep = "")
    r = GET(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost = 0,ssl_verifypeer = 0) )
      content = rawToChar(r$content)
      results = fromJSON(content)
    if(r$status == 500){
      print("Error in receiving results from simulation")
      return("error")
    }
    if (results$status == "error") {
      if(writing_counter<10){
        print("Status: error; Waiting for results")
        }
      Sys.sleep(10)
    }
    else{
      print("Point returned")
      print(toJSON(results$result))
      return(results$result)
    }
  }
})


setMethod("mark_as_complete", "Scalarm", function(.Object, result) {
  url = paste(.Object@http_schema,"://", .Object@address,"/experiments/",.Object@experiment_id,"/mark_as_complete.json",sep = "")
  encoded_url = URLencode(result)
  modified_url = paste(url,"?results=",encoded_url, sep = "")
  r = POST(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost = 0,ssl_verifypeer = 0) )
  print( "Marked as complete and sent")
  print(result)
})


