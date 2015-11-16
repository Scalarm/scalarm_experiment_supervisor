import json
import math
import requests
from requests.auth import HTTPBasicAuth
import time

class Scalarm:
    def __init__(self, user, password, experiment_id, http_schema, address, parameters_ids, verify):
        self.user = user
        self.password = password
        self.experiment_id = experiment_id
        self.address = address
        self.parameters_ids = parameters_ids
        self.schema = http_schema
        self.verify = verify

    def schedule_point(self, params):
        print 'Scheduling: ', params
        params_dict = {}
        for id, param in zip(self.parameters_ids, params):
            params_dict[id] = param
        print json.dumps(params_dict)
        r = requests.post("%s://%s/experiments/%s/schedule_point.json" % (self.schema, self.address, self.experiment_id),
                          auth=HTTPBasicAuth(self.user, self.password),
                          params={'point': json.dumps(params_dict)},
                          verify=self.verify)
        print r.text

    def get_result(self, params):
        print 'Getting result: ', params
        params_dict = {}
        for id, param in zip(self.parameters_ids, params):
            params_dict[id] = param
        while True:
            r = requests.get("%s://%s/experiments/%s/get_result.json" % (self.schema, self.address, self.experiment_id),
                             auth=HTTPBasicAuth(self.user, self.password),
                             params={'point': json.dumps(params_dict)},
                             verify=self.verify)
            print r.text
            decoded_result = json.loads(r.text)
            if decoded_result["status"] == "error":
                print decoded_result["message"]
                time.sleep(1)
                continue
            elif decoded_result["status"] == "ok":
                if "moe" not in decoded_result["result"]:
                    raise KeyError("Field 'result' must contain key named 'moe' with numeric value")
                return decoded_result["result"]["moe"]

    def mark_as_complete(self, result):
        print 'Uploading result: ', result
        r = requests.post("%s://%s/experiments/%s/mark_as_complete.json" % (self.schema, self.address, self.experiment_id),
                          auth=HTTPBasicAuth(self.user, self.password),
                          params={'results': json.dumps(result)},
                          verify=self.verify)
        print r.text

