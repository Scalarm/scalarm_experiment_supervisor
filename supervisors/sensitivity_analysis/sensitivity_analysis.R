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


validate <- function(obj , type , pattern=NULL){
    if (type != typeof(obj)){
        stop("Variable has wrong type")
    }
    if (!is.null(pattern)){
        if (grepl(pattern, obj) == FALSE){
            stop("Variable doesn't match")
        }
    }
    return
}

setGeneric("morris_f", function(options, parameters) {
    binf <- c()
    bsup <- c()
    factors <- c()
    input_amount <- length(parameters)
    for (parameter_number in 1:input_amount) {
        binf[parameter_number] <- parameters[[parameter_number]]$min
        bsup[parameter_number] <- parameters[[parameter_number]]$max
        factors[parameter_number] <- parameters[[parameter_number]]$id
    }

    if (options$design == "oat") {
        Uncomplete_object <- morris(model = NULL, factors = factors,
                                binf, bsup, r = options$size,
                                design = list(type = "oat",
                                levels = options$levels,
                                grid.jump = options$gridjump))
    } else {
        Uncomplete_object <- morris(model = NULL, factors = factors,
                                binf, bsup, r = options$size,
                                design = list(type = "simplex",
                                scale.factors = options$factor))
    }

    results = list(Uncomplete_object = Uncomplete_object, factors = factors)

    return (results)
})

setGeneric("fast_f", function(options, parameters) {
    bqarg <- c()
    bq <- c()
    factors <- c()
    input_amount <- length(parameters)

    for (parameter_number in 1:input_amount) {
        bq[parameter_number] <- options$design_type
        bqarg[[parameter_number]] <- list(min = parameters[[parameter_number]]$min, max = parameters[[parameter_number]]$max)
        factors[parameter_number] <- parameters[[parameter_number]]$id
    }

    Uncomplete_object <- fast99(model = NULL, factors = factors, n = options$sample_size,
                                  q = bq, q.arg = bqarg)


    results = list(Uncomplete_object = Uncomplete_object, factors = factors)
    return (results)
})


setGeneric("pcc_f", function(options, parameters) {
  binf <- c()
  bsup <- c()
  factors <- c()
  input_amount <- length(parameters)

  for (parameter_number in 1:input_amount) {
    binf[parameter_number] <- parameters[[parameter_number]]$min
    bsup[parameter_number] <- parameters[[parameter_number]]$max
    factors[parameter_number] <- parameters[[parameter_number]]$id
  }
  X = list()
  for (idx in 1:input_amount) {
    X = append(X,  structure(list(runif(options$sample_size,binf[idx],bsup[idx])),.Names =factors[idx]))
  }
  X = data.frame(X)
  Uncomplete_object <- list("X"=X)
  results = list(Uncomplete_object = Uncomplete_object, factors = factors)
  return(results)
})

setGeneric("morris_load_result_moes", function(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json) {
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
    return (structure(list(output_result), .Names = c("moes")))

})

setGeneric("fast_load_result_moes", function(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json) {
    for (output_number in 1:output_amount) {
        Complete_object <- tell(Uncomplete_object, results_array[,
          output_number])

        first_order <- (Complete_object$D1 / Complete_object$V)
        total_order <- (1 - (Complete_object$Dt / Complete_object$V))

        for (index in 1:length(Complete_object$V)) {
            if (is.na(first_order[index])) {
                first_order[index] <- 0
            }
            if (is.na(total_order[index])) {
                total_order[index] <- 1
            }
        }

        moe_result = structure(list())

        for (counted_values in 1:length(factors)) {
          parameter_results = list(first_order = first_order[[counted_values]],
            total_order = total_order[[counted_values]])
          moe_result = append(moe_result, structure(list(parameter_results),
            .Names = factors[[counted_values]]))
        }
        output_result = append(output_result, structure(list(moe_result),
          .Names = output_to_json[output_number]))
    }
    return (structure(list(output_result), .Names = c("moes")))

})

setGeneric("pcc_load_result_moes", function(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json, options) {
  for (output_number in 1:output_amount) {
    Complete_object <- pcc(Uncomplete_object$X, results_array[,output_number], nboot = options$nboot)
    moe_result = structure(list())
    for (idx in 1:length(factors)) {
      parameter_results = list("original" = Complete_object$PCC[[1]][idx], "min_c_i" = Complete_object$PCC[[4]][idx], "max_c_i" = Complete_object$PCC[[5]][idx])
      moe_result = append(moe_result, structure(list(parameter_results),
                                                .Names = factors[[idx]]))
    }
    output_result = append(output_result, structure(list(moe_result),
                                                    .Names = output_to_json[output_number]))
  }
  return (structure(list(output_result), .Names = c("moes")))

})


if (!interactive()) {
  file_path = commandArgs(FALSE)[4]
  directory = str_match(file_path, "--file=(/.*)/sensitivity_analysis.R")
  
  if (is.na(directory[, 1]) == TRUE) {
    stop("Error while reading file path")
  }
  scalarm_api = paste(directory[1 , 2] , "/scalarmapi.R", sep = "")
  source(scalarm_api)
}    
    
    setGeneric("sensitivity_analysis_function" , function(.Object, parameters, options, method_type) {})
    
    setMethod("sensitivity_analysis_function" , "Scalarm" , function(.Object, 
                parameters, options, method_type) {

        results_moes = list()
        if (method_type == "morris") {
            method = list(sensitivity_analysis_method = "morris")
            results = morris_f(options, parameters)
            Uncomplete_object = results$Uncomplete_object
            factors = results$factors
        } else if (method_type == "fast") {
            method = list(sensitivity_analysis_method = "fast")
            results = fast_f(options, parameters)
            Uncomplete_object = results$Uncomplete_object
            factors = results$factors
        } else {
            method = list(sensitivity_analysis_method = "pcc")
            results = pcc_f(options, parameters)
            Uncomplete_object = results$Uncomplete_object
            factors = results$factors
        }

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

            if (method_type == "morris") {
                results_moes = morris_load_result_moes(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json)
            } else if (method_type == "fast") {
                results_moes = fast_load_result_moes(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json)
            } else {
                results_moes = pcc_load_result_moes(output_amount, Uncomplete_object, results_array, factors, output_result, output_to_json, options)
            }


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
    method_type = config_file$method_type
    if (method_type == "morris") {
        validate(config_file$design_type,"character","oat|simplex")
        validate(config_file$size,"double")
        design = config_file$design_type
        if (design == "oat") {
            validate(config_file$gridjump , "double")
            validate(config_file$levels , "double")
            options = list(design = design, size = config_file$size, gridjump = config_file$gridjump,
                       levels = config_file$levels)
        } else {
            validate(config_file$factor , "double")
            options = list(design = design, size = config_file$size, factor = config_file$factor)
        }
    } else if (method_type == "fast") {
        validate(config_file$sample_size ,"double")
        validate(config_file$design_type_fast ,"character")
        options = list(sample_size = config_file$sample_size, design_type = config_file$design_type_fast)
    } else if (method_type == "pcc") {
        validate(config_file$sample,"double")
        validate(config_file$nboot,"double")
              options = list(sample_size = config_file$sample, nboot = config_file$nboot)
          }
    parameters_ids = lapply(config_file$parameters, "[[", "id")
    if (!is.null(config_file$verifySSL)){
        verify = config_file$verifySSL
    }
    scalarm = Scalarm(config_file$user, config_file$password, config_file$experiment_id,
                    config_file$address, parameters_ids, config_file$http_schema, verify)
    sensitivity_analysis_function(scalarm, config_file$parameters, options, method_type)
}