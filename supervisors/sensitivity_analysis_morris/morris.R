require(methods)

r = "http://cran.uk.r-project.org"
list.of.packages <- c("rjson", "sensitivity", "httr", "stringr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if (length(new.packages) > 0)
    install.packages(new.packages, repos = r, quiet = TRUE)

library("rjson")
library("sensitivity")
library("httr")
library("stringr")




setGeneric("morris_f", function(options, factors,binf, bsup) {
  if (options$design == "oat") {
    Uncomplete_object <- morris(model = NULL, factors = factors, 
                                binf, bsup, r = options$size,
                                design = list(type = "oat", 
                                levels = options$levels,
                                grid.jump = options$gridjump))
    return(Uncomplete_object)
    }
  else {
    Uncomplete_object <- morris(model = NULL, factors = factors, 
                                binf, bsup, r = options$size,
                                design = list(type = "simplex", 
                                scale.factors = options$factor))
    return(Uncomplete_object)
    }

})

if (!interactive()) {
  file_path = commandArgs(FALSE)[4]
  directory = str_match(file_path, "--file=(/.*)/morris.R")
  
  if (is.na(directory[, 1]) == TRUE) {
    stop("Error while reading file path")
  }
  scalarm_api = paste(directory[1 , 2] , "/scalarmapi.R", sep = "")
  source(scalarm_api)
}    
    
    setGeneric("sensitivity_analysis_function" , function(.Object, parameters, options) {})
    
    setMethod("sensitivity_analysis_function" , "Scalarm" , function(.Object, 
        parameters, options) {
        method = list(sensitivity_analysis_method = "morris")
        results_moes = list()
        binf <- c()
        bsup <- c()
        factors <- c()
        input_amount <- length(parameters)

        for (parameter_number in 1:input_amount) {
            binf[parameter_number] <- parameters[[parameter_number]]$min
            bsup[parameter_number] <- parameters[[parameter_number]]$max
            factors[parameter_number] <- parameters[[parameter_number]]$id
        }

        Uncomplete_object = morris_f(options, factors, binf, bsup)
        starting_points <- Uncomplete_object["X"]

        if (any(is.na(Uncomplete_object$X)) == TRUE) {
            stop("Cannot compute values - NaN in samples")
        } else {
            experiment_size <- nrow(starting_points$X)
            for (row_number in 1:experiment_size) {
              params <- c(starting_points$X[row_number, ])
              if (is.null(check_repetitions(.Object, params))) {
                schedule_point(.Object, params)
              }
            }
            for (row_number in 1:experiment_size) {
                new_point <- c()
                params <- c(starting_points$X[row_number, ])
                result = get_result(.Object, params)
                if (result == "error"){
                  stop("Error in receiving results from simulation")
                }
                point_result <- result
                if (row_number == 1) {
                  # we assume that simulation was completed propely
                  output_amount = length(point_result)
                  results_array <- data.frame(matrix(NA, ncol = output_amount, 
                    nrow = experiment_size))
                  output_to_json <- names(point_result)
                }
                for (output in 1:output_amount) {
                  new_point <- append(new_point, point_result[output])
                }
                results_array[row_number, ] <- new_point
            }
            output_result = structure(list())

            for (output_number in 1:output_amount) {
                Complete_object <- tell(Uncomplete_object, results_array[, 
                  output_number])
                mu <- apply(Complete_object$ee, 2, mean)
                mu.star <- apply(Complete_object$ee, 2, function(Complete_object) mean(abs(Complete_object)))
                sigma <- apply(Complete_object$ee, 2, sd)
                moe_result = structure(list())
                
                for (counted_values in 1:length(factors)) {
                  parameter_results = list(mean = mu[[counted_values]], 
                    absolute_mean = mu.star[[counted_values]], standard_deviation = sigma[[counted_values]])
                  moe_result = append(moe_result, structure(list(parameter_results), 
                    .Names = factors[[counted_values]]))
                }
                output_result = append(output_result, structure(list(moe_result), 
                  .Names = output_to_json[output_number]))
            }
            results_moes = structure(list(output_result), .Names = c("moes"))
        }
        results = append(method, results_moes)
        JSON_to_send = toJSON(results)
        print(JSON_to_send)
        mark_as_complete(.Object, JSON_to_send)
        
    })

if (!interactive()) {
  if (length(commandArgs(TRUE)) < 1) {
    config_file = fromJSON(file = "config.json")
  } else {
    config_file = fromJSON(file = commandArgs(TRUE)[1])
  }
  verify = FALSE
  design = config_file$design_type
  if (design == "oat") {
    options = list(design = design, size = config_file$size, gridjump = config_file$gridjump, 
                   levels = config_file$levels)
  }
  else {
    options = list(design = design, size = config_file$size, factor = config_file$factor)
  }
  parameters_ids = lapply(config_file$parameters, "[[", "id")
  if (!is.null(config_file$verifySSL)){
    verify = config_file$verifySSL
  }
  scalarm = Scalarm(config_file$user, config_file$password, config_file$experiment_id, 
                    config_file$address, parameters_ids, config_file$http_schema, verify)
sensitivity_analysis_function(scalarm, config_file$parameters, options)
}
