require(methods)
library("rjson", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")
library("sensitivity", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")
library("hash", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")
library("httr", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.1")

# TODO how to install packages
setGeneric("sensitivity_analysis_function", function(.Object, parameters, r) {
  .Object
})

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
  modified_url<- paste(url,"?point=",encoded_url, sep="")
  library(RCurl) #
  r=POST(modified_url,authenticate(.Object@user, .Object@password, type = "basic"), config( ssl_verifyhost=0,ssl_verifypeer=0) )
  print( "Marked as complete and sent")
  print(result)
  r
})





setMethod("sensitivity_analysis_function", "Scalarm", function(.Object, parameters, r) { # wielkosc i reszta params na razie typ tylko oat
  binf<- c()
  bsup<- c()
  factors <- c()
  
  
  input_amount<- length(parameters)
  for(parameter_number in 1:input_amount){
    binf[parameter_number]<-parameters[[parameter_number]]$min
    bsup[parameter_number]<-parameters[[parameter_number]]$max
    factors[parameter_number]<-parameters[[parameter_number]]$id
  }
  Uncomplete_object<-morris(model = NULL, factors =factors,
                            binf , bsup ,r = r,
                            design = list(type = "oat", levels = 5, grid.jump = 3)) #check for NA o overflow
  starting_points<- Uncomplete_object["X"]
  experiment_size<-nrow(starting_points$X) 
  
  for(row_number in 1:experiment_size ){
    new_point<-c()
    params <- c(starting_points$X[row_number,])
    schedule_point(.Object, params)
    result =get_result(.Object, params)
    point_result<-result
    if(row_number==1){ #error point
      output_amount=length(point_result)
      results_array<-data.frame(matrix(NA, ncol =output_amount, nrow =experiment_size ))
      output_to_json<-names(point_result)
    }
    for(output in 1:output_amount){
      new_point<-append(new_point,point_result[output])
    }
    results_array[row_number,]<- new_point
  }
  output_result= structure(list())
  for(output_number in 1:output_amount){
    Complete_object <-tell(Uncomplete_object,results_array[,output_number])
    mu <- apply(Complete_object$ee, 2, mean)
    mu.star <- apply(Complete_object$ee, 2, function(Complete_object) mean(abs(Complete_object)))
    sigma <- apply(Complete_object$ee, 2, sd)
    moe_result= structure(list())
    
    for(counted_values in 1:length(factors)){
      parameter_results= list("mu"=mu[[counted_values]], "mu.star"=mu.star[[counted_values]],"sigma"=sigma[[counted_values]])
      moe_result= append(moe_result, structure(list(parameter_results), .Names=factors[[counted_values]]))
    }
    output_result= append(output_result, structure(list(moe_result), .Names=output_to_json[output_number]))
  }
  results_moes=structure(list(output_result),.Names=c("moes"))
  method=list("sensitivity_analysis_method"="morris")
  results=structure(list(append(method,results_moes)),.Names="result")
  results=append(results,list("error"="null"))
  JSON_to_send=toJSON(results)
  mark_as_complete(.Object,JSON_to_send)
  
})

if(!interactive()){
  if ( length(commandArgs(TRUE)) < 1 ){ # check if it is working
    config_file =  fromJSON(file="config.json")
  }
  else {
    config_file = fromJSON(file = commandArgs(TRUE)[1])
  }
  verify=FALSE
  parameters_ids=lapply(config_file$parameters, "[[", "id")
  if(!is.null(config_file$verifySSL))
    verify= config_file$verifySLL
  scalarm = Scalarm(config_file$user,
                    config_file$password,
                    config_file$experiment_id,
                    config_file$address,
                    parameters_ids,
                    config_file$http_schema,
                    verify)
  sensitivity_analysis_function(scalarm, config_file$parameters, 6) # size change
}

