
import json
from pyDOE import *
import numpy as np
import pandas as pd
from statsmodels.formula.api import ols
import sys
import random
from scalarmapi import Scalarm

NO_INFLUENCE = 0.2
init_search_space_min =  [0, -90]
init_search_space_max =  [60, -70]
NUMBER_OF_CENTER_POINTS = 4
N = 12




def RSM(parameters, search_space, limit):

    points = generate_RSM_design(parameters)
    points_to_sim = unnormalize(points,search_space[0],search_space[1])
    results = send(points_to_sim)
    #Intercept == constans?
    res = regression_analysis(results, parameters, "+")
    regression = res.params
    if(check(results , parameters, regression)==True):
        scalarm.mark_as_complete({'min': list(search_space[0]), 'max': list(search_space[1])})
        return
    for param in regression:
        param = float('{0:.10f}'.format(param))

    stepping = np.zeros(len(regression)-1)
    for step in range(0,N):
    ####        param1 = float('{0:.10f}'.format(regression[0]))
    ####        param2 = float('{0:.10f}'.format(regression[1]))
    ##        
        stepp = [step]
        for idx in range(2,len(regression)):
            stepp = np.append(stepp, step/regression[1]*regression[idx])
        stepping = np.vstack([stepping, stepp])
    stepping = np.delete(stepping, (0), axis=0)
    print "stepping"
    print stepping
    experiment = unnormalize(stepping, search_space[0], search_space[1])
##    index = deleting(experiment, limit)
##    if index > -1:
##       for i in range(index, len(experiment)):
##           del experiment[index]
##    print experiment
    results = send(experiment)
    #how to display
    # stopping points
    new_space = new_search_space(results)
    print "search space"
    print search_space
    print "new_space"
    print new_space
    for test, lim in zip( new_space[1], limit[1]):
        if abs(test) > abs(lim):
            print "Extended space"
            new_space = np.array(new_space, dtype = int)
            print new_space 
            scalarm.mark_as_complete({'min': list(new_space[0]), 'max': list(new_space[1])})
            return
    print new_space
    RSM(parameters, new_space, limit)

def deleting(experiment, limit):
    for idx, param in enumerate(experiment):
        for number, m in zip(param, limit[1]):
            print number, m, idx
            if number > m:
                index = idx
                return idx
            
def send(points_to_sim):
    for point in points_to_sim:
        scalarm.schedule_point(point)
        res = np.append(point,scalarm.get_result(point));
        if point == points_to_sim[0]:
            results = res
        else :
            results = np.vstack([results,res])
    return results

def new_search_space(results):
    print "results"
    print results






    maximum = max(results[:,-1])
    mini = []
    maxi = []
    print "Maximum"
    print maximum
    for idx , row in enumerate(results):
        if maximum == row[-1]:
            if idx > 0 and idx < len(results)-1:
                mini = results[idx-1]
                maxi = results[idx+1]
            elif idx == 0:
                mini = results[idx]
                maxi = results[idx+1]
            elif idx == len(results)-1:
                mini = results[idx-1]
                maxi = results[idx]
    mini = np.delete(mini, -1)
    maxi = np.delete(maxi, -1)
    print "Przedzial"
    print [mini, maxi]
    return [mini, maxi]

def generate_RSM_design(parameters):
    points = ff2n(len(parameters))
    center_points = [0 for x in range(len(parameters))]
    for number in range(0,NUMBER_OF_CENTER_POINTS):
        points = np.vstack([points,center_points])
    return points

def normalize(points, lower_limit, upper_limit):
    normalized = np.array(len(points[0]))
    for point in points:
        to_sim = []
        for param, min, max in zip(point,lower_limit,upper_limit):
            x= (param-min)/(max-min)*2-1
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
    experiment = {}
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

def check(results , parameters, regression):
    print "Params influecne"
    print regression
##    for param in range(1,len(regression)):
##        if abs(regression[param]) < NO_INFLUENCE:
##            return True
##    res = regression_analysis(results, parameters, "*")
##    print "Paramentry"
##    print res.params
##    if abs(res.params[-1]) > NO_INFLUENCE:
##        return True
    return False

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

RSM(parameters_ids, [init_search_space_min, init_search_space_max], [lower_limit, upper_limit])
