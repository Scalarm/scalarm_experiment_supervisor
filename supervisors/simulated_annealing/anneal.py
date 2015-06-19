import scipy.optimize as scopt
import json
import sys
from scalarmapi import Scalarm


def call_scalarm(x):
    print 'schedule_point'
    scalarm.schedule_point(x)
    print 'get_result'
    return scalarm.get_result(x)


def to_csv(data):
    s = str(data[0])
    for l in data[1:]:
        s += ','
        s += str(l)
    return s


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

    for param in config["parameters"]:
        parameters_ids.append(param["id"])
        lower_limit.append(param["min"])
        upper_limit.append(param["max"])
        start_point.append(param["start_value"])


    scalarm = Scalarm(config['user'],
                      config['password'],
                      config['experiment_id'],
                      config['http_schema'],
                      config["address"],
                      parameters_ids,
                      config['verifySSL'] if 'verifySSL' in config else False)

    res = scopt.anneal(func=call_scalarm,
                       x0=start_point,
                       full_output=True,
                       schedule=config['schedule'],
                       lower=lower_limit,
                       upper=upper_limit,
                       maxiter=config['maxiter'],
                       dwell=config['dwell'])

    print 'mark_as_complete'
    scalarm.mark_as_complete({'result': res[1], 'values': to_csv(res[0])})


