import json
from pyDOE import *
import numpy as np
import pandas as pd
from statsmodels.formula.api import ols
import statsmodels.api as sm
import sys
import math
import random
import scipy
#from scalarmapi import Scalarm

NO_INFLUENCE = 0.01

if __name__ == "__main__":
    if len(sys.argv) < 2:
        config_file = open('config.json')
    else:
        config_file = open(sys.argv[1])
    config = json.load(config_file)
    config_file.close()

max_iterations = config['max_iterations']
N = 40


def RSM(parameters, search_space, limit, iteration):
    if iteration>max_iterations:
        scalarm.mark_as_complete({'min': list(search_space[0]), 'max': list(search_space[1]), 'stop':'Maximal number of iteration reached'})
        return
    design_points = ccdesign(len(parameters))
    points_to_sim = unnormalize(design_points,search_space[0],search_space[1])
    simulations_results = perform_simulations(points_to_sim)
    #Intercept == constans?
    regression_results = regression_analysis(simulations_results, parameters, "+")
    model = regression_results.params
    sum_of_squares = 0
    for idx in range(1,len(model)):
        sum_of_squares = sum_of_squares+model[idx]*model[idx]
    sum_of_squares = math.sqrt(sum_of_squares)
    if(check_linearity(simulations_results , parameters, model, search_space)==True):
        return
    experiment_points = np.zeros(len(model)-1)
    for step in range(0,N):
        steps = [step*model[1]/sum_of_squares]
        for idx in range(2,len(model)):
            steps = np.append(steps, step*model[idx]/sum_of_squares)
        experiment_points = np.vstack([experiment_points, steps])
    experiment_points = np.delete(experiment_points, (0), axis=0)
    experiment_points = unnormalize(experiment_points, search_space[0], search_space[1])
    simulations_results = perform_simulations(experiment_points)
    new_space = new_search_space(simulations_results)
    for new_params, old_params in zip( new_space[1], limit[1]):
        if abs(new_params) > abs(old_params):
            new_space = np.array(new_space, dtype = int)
            scalarm.mark_as_complete({'min': list(new_space[0]), 'max': list(new_space[1]), 'stop':'Maximal parameter space reached'})
                return
    RSM(parameters, new_space, limit, iteration+1)


            
def perform_simulations(points_to_sim):
    for point in points_to_sim:
        scalarm.schedule_point(point)
    for point in points_to_sim:
        res = np.append(point,scalarm.get_result(point));
        if point == points_to_sim[0]:
            results = res
        else :
            results = np.vstack([results,res])
    return results

def new_search_space(results):
    extremum = max(results[:,-1])
    minimum = []
    maximum = []
    for idx , row in enumerate(results):
        if extremum == row[-1]:
            if idx > 0 and idx < len(results)-1:
                minimum = results[idx-1]
                maximum = results[idx+1]
            elif idx == 0:
                minimum = results[idx]
                maximum = results[idx+1]
            elif idx == len(results)-1:
                minimum = results[idx-1]
                maximum = results[idx]
    minimum = np.delete(minimum, -1)
    maximum = np.delete(maximum, -1)
    return [minimum, maximum]


def normalize(points, lower_limit, upper_limit):
    normalized_points = np.array(len(points[0]))
    for point in points:
        to_sim = []
        for param, min, max in zip(point,lower_limit,upper_limit):
            to_sim.append((param-min)/(max-min)*2-1)
        normalized_points = np.vstack([normalized_points,to_sim])
    return normalized_points

def unnormalize(points, lower_limit, upper_limit):
    unnormalized_points = []
    for point in points:
        to_sim = []
        for param, min, max in zip(point,lower_limit,upper_limit):
            to_sim.append((param+1)*(max-min)/2+min)
        unnormalized_points.append(to_sim)
    return unnormalized_points

def create_data(results,parameters):
    experiment = {}
    for idx in range(0,len(parameters)):
        experiment[parameters[idx]] = pd.Series(results[:,idx])
    experiment['output'] = pd.Series(results[:,len(parameters)])
    return experiment

def create_formula(parameters,sign):
    formula_output = "output ~ "
    formula_input = sign.join(parameters_ids)
    formula = "%s%s" %(formula_output,formula_input)
    return formula

def regression_analysis(points, parameters, sign):
    data = create_data(points, parameters)
    formula = create_formula(parameters, sign)
    mod = ols(str(formula),data = data)
    result = mod.fit()
    return result

def check_linearity(results , parameters, regression, search_space):
    for param in range(1,len(regression)):
        if abs(regression[param]) < NO_INFLUENCE:
            scalarm.mark_as_complete({'min': list(search_space[0]), 'max': list(search_space[1]), 'stop': 'One of parameters has no influence'})
            return True
    res = regression_analysis(results, parameters, "*")
    for idx in range(1,len(res.params)):
        if idx & (idx - 1) != 0:
            if abs(res.params[x]) > NO_INFLUENCE:
                scalarm.mark_as_complete({'min': list(search_space[0]), 'max': list(search_space[1]), 'stop': 'Steepest ascent method is not suitable anymore'})
                return True
    return False






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

init_search_space_min =[0]* len(lower_limit)
init_search_space_max = [0]* len(upper_limit)
for x in range(0,len(lower_limit)):
    space_len = abs(lower_limit[x])+abs(upper_limit[x])
    center_point = space_len/2+ lower_limit[x]
    init_search_space_min[x] = center_point - space_len/20
    init_search_space_max[x] = center_point + space_len/20

print "Initial search space"
print init_search_space_min
print init_search_space_max

scalarm = Scalarm(config['user'],
	config['password'],
	config['experiment_id'],
        config['http_schema'],
        config['address'],
        parameters_ids,
        config['verifySSL'] if 'verifySSL' in config else False)

RSM(parameters_ids, [init_search_space_min, init_search_space_max], [lower_limit, upper_limit], 1)
