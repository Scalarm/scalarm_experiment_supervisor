import scipy.optimize as scopt
import json
import sys
import math
import random
from scalarmapi import Scalarm

def to_csv(data):
    s = str(data[0])
    for l in data[1:]:
        s += ','
        s += str(l)
    return s

def acceptance_probability(best_value, current_best_value, temperature):
    if (current_best_value < best_value):
        return 1.

    return math.exp((best_value - current_best_value) / temperature)

def generate_neighbour(best_point, lower_limit, upper_limit, temperature, initial_temperature):
    neighbour = []
    for i in xrange(0, len(best_point)):
        change_limit = ((upper_limit[i] - lower_limit[i]) * temperature / initial_temperature) / 2.
        min_val = max(lower_limit[i], best_point[i] - change_limit)
        max_val = min(upper_limit[i], best_point[i] + change_limit)
        val = random.uniform(min_val, max_val)
        neighbour.append(val)

    return neighbour

def anneal(initial_temperature,
           cooling_rate,
           start_point,
           lower_limit,
           upper_limit,
           points_limit,
           dwell,
           spread):

    if (points_limit == 0):
        points_limit = float('inf') 
    temperature = float(initial_temperature)
    cooling_rate = float(cooling_rate)

    best_point = start_point
    scalarm.schedule_point(best_point)
    points_limit -= 1
    best_value = float(scalarm.get_result(best_point))
    
    while (temperature > 1. and points_limit > 0):
        for i in xrange(0, dwell):
            neighbourhood = []
            for j in xrange(0, spread):
                neighbour = generate_neighbour(best_point, lower_limit, upper_limit, temperature, initial_temperature)
                if (points_limit > 0):
                    points_limit -= 1
                    scalarm.schedule_point(neighbour)
                    neighbourhood.append(neighbour)

            current_best_point = []
            current_best_value = float('inf')
            for j in xrange(0, len(neighbourhood)):
                current_point = neighbourhood[j]
                current_value = float(scalarm.get_result(current_point))
                if (current_value < current_best_value):
                    current_best_point, current_best_value = current_point, current_value

            if (acceptance_probability(best_value, current_best_value, temperature) > random.random()):
                best_point, best_value = current_best_point, current_best_value
        
        temperature *= 1 - cooling_rate
    
    return best_point, best_value


if __name__ == "__main__":
    if len(sys.argv) < 2:
        config_file = open('config.json')
    else:
        config_file = open(sys.argv[1])
    config = json.load(config_file)
    config_file.close()

    parameters_ids = []
    lower_limit = []
    upper_limit = []
    start_point = []

    for param in config['parameters']:
        parameters_ids.append(param['id'])
        lower_limit.append(param['min'])
        upper_limit.append(param['max'])
        start_point.append(param['start_value'])


    scalarm = Scalarm(config['user'],
                      config['password'],
                      config['experiment_id'],
                      config['http_schema'],
                      config['address'],
                      parameters_ids,
                      config['verifySSL'] if 'verifySSL' in config else False)

    res = anneal(initial_temperature=config['initial_temperature'],
                 cooling_rate=config['cooling_rate'],
                 start_point=start_point,
                 lower_limit=lower_limit,
                 upper_limit=upper_limit,
                 points_limit=config['points_limit'],
                 dwell=config['dwell'],
                 spread=config['spread'])

    print 'mark_as_complete'
    scalarm.mark_as_complete({'result': res[1], 'values': to_csv(res[0])})


