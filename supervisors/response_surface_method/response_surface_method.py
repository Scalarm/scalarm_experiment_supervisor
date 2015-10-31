from decimal import Decimal
import json
from pyDOE import *
import numpy as np
import pandas as pd
from statsmodels.formula.api import ols
from scalarmapi import Scalarm
import sys

init_search_space_min =  [50, -20, 20]
init_search_space_max =  [150, 20, 70]
number_of_center_points = 4
results_mock = np.array([[50.0, -20.0, 20.0, 50], [150.0, -20.0, 20.0, 20], [50.0, 20.0, 20.0, 11], [150.0, 20.0, 20.0, 13], [50.0, -20.0, 70.0, 24], [150.0, -20.0, 70.0, 22], [50.0, 20.0, 70.0, 52], [150.0, 20.0, 70.0, 67], [100.0, 0.0, 45.0, 23], [100.0, 0.0, 45.0, 14], [100.0, 0.0, 45.0, 13], [100.0, 0.0, 45.0, 22]])
N = 12




def RSM(parameters, search_space_min,search_space_max, number_of_center_points):
    # check if search space is in iniital space
    points = generate_RSM_design(parameters, number_of_center_points)
    points_to_sim = unnormalize(points,search_space_min,search_space_max)
    for point in points_to_sim:
        scalarm.schedule_point(point)
        if point == points_to_sim[0]:
            results = scalarm.get_result(point);
        results = np.vstack([results,scalarm.get_result(point)])
    print(results)
    if(check_cross(results, parameters)):
       return
    #Intercept == constans?
    res = regression_analysis(results, parameters, "+")
    regression = res.params

    stepping = []
    for step in range(0,N):
        stepping.append([step,step/regression["parameter1"]*regression["parameter2"]])
    experiment = unnormalize(stepping, search_space_min, search_space_max)
    print(experiment)
    for point in experiment:
        scalarm.schedule_point(point)
        if point == experiment[0]:
            experiment_results = scalarm.get_result(point);
        experiment_results = np.vstack([results,scalarm.get_result(point)])
    #next interations
    scalarm.mark_as_complete({'result': {experiment_result}, 'values': "no_error"})

def generate_RSM_design(parameters, number_of_center_points):
    points = ff2n(len(parameters))
    center_points = [0 for x in range(len(parameters))]
    for number in range(0,number_of_center_points):
        points = np.vstack([points,center_points])
    return points

def normalize(points, lower_limit, upper_limit):
    normalized = np.array(len(points[0]))
    for point in points:
        to_sim = []
        for param, min, max in zip(point,lower_limit,upper_limit):
            x= Decimal((param-min)/(max-min)*2-1)
            to_sim.append(x)
        normalized = np.vstack([normalized,to_sim])
    return normalized

def unnormalize(points, lower_limit, upper_limit):
    unnormalized = []
    for point in points:
        to_sim = []
        for param, min, max in zip(point,lower_limit,upper_limit):
            x=(param+1)*(max-min)/2+min
            to_sim.append(x)
        unnormalized.append(to_sim)
    return unnormalized

def create_data(results,parameters):
    print(results)
    experiment = {}
    print("bbbbbbbbbbbbbb")

    for x in range(0,len(parameters)):
        experiment[parameters[x]] = pd.Series(results[:,x])
    experiment['output'] = pd.Series(results[:,len(parameters)])
    return experiment

def create_formula(parameters,sign):
    formula_output = "output ~ "
    formula_input = sign.join(parameters_ids)
    formula = "%s%s" %(formula_output,formula_input)
    return formula

def regression_analysis(results, parameters, sign):
    data = create_data(results, parameters)
    formula = create_formula(parameters, sign)
    mod = ols(str(formula),data = data)
    res = mod.fit()
    return res

def check_cross(results, parameters):
    regression_analysis(results, parameters, "*")
    return 0

if __name__ == "__main__":
    if len(sys.argv) < 2:
        config_file = open('config.json')
    else:
        config_file = open(sys.argv[1])
    config = json.load(config_file)
    config_file.close()

#Maybe user can choose only some parameteres
parameters = config["parameters"]
parameters_ids = []
lower_limit = []
upper_limit = []
start_point = []

for param in parameters:
    parameters_ids.append(param["id"])
    lower_limit.append(param["min"])
    upper_limit.append(param["max"])

scalarm = Scalarm(config['user'],
                  config['password'],
                  config['experiment_id'],
                  config['http_schema'],
                  config['address'],
                  parameters_ids,
                  config['verifySSL'] if 'verifySSL' in config else False)

RSM(parameters_ids, init_search_space_min, init_search_space_max, number_of_center_points)
