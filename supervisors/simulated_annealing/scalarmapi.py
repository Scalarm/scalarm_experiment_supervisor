import json
import requests
from requests.auth import HTTPBasicAuth
import time
import logging
INFO_WITHOUT_WARNINGS = 35
logging.captureWarnings(True)
logging.basicConfig(level=INFO_WITHOUT_WARNINGS, format='%(asctime)-15s %(message)s')


def log(msg):
    logging.log(INFO_WITHOUT_WARNINGS, msg)


SLEEP_DURATION_BETWEEN_QUERIES = 5  # seconds
ERROR_OCCURRENCES_BETWEEN_WARNING = 10


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
        log('Scheduling: %s' % str(params))
        params_dict = {}
        for id, param in zip(self.parameters_ids, params):
            params_dict[id] = param
        log(json.dumps(params_dict))
        r = requests.post("%s://%s/experiments/%s/schedule_point.json" % (self.schema, self.address, self.experiment_id),
                          auth=HTTPBasicAuth(self.user, self.password),
                          params={'point': json.dumps(params_dict)},
                          verify=self.verify)
        log(r.text)

    def get_result(self, params):
        log('Getting result: %s' % str(params))
        params_dict = {}
        for id, param in zip(self.parameters_ids, params):
            params_dict[id] = param
        points_not_found_counter = 0
        while True:
            r = requests.get("%s://%s/experiments/%s/get_result.json" % (self.schema, self.address, self.experiment_id),
                             auth=HTTPBasicAuth(self.user, self.password),
                             params={'point': json.dumps(params_dict)},
                             verify=self.verify)
            decoded_result = json.loads(r.text)
            if decoded_result["status"] == "error":
                if decoded_result["message"] == "Point not found":
                    points_not_found_counter += 1
                else:
                    log(r.text)
                    raise RuntimeError(decoded_result["message"])
                if points_not_found_counter == ERROR_OCCURRENCES_BETWEEN_WARNING:
                    points_not_found_counter = 0
                    log("Point not available after 10 attempts")
                time.sleep(SLEEP_DURATION_BETWEEN_QUERIES)
                continue
            elif decoded_result["status"] == "ok":
                if "moe" not in decoded_result["result"]:
                    raise KeyError("Field 'result' must contain key named 'moe' with numeric value")
                return decoded_result["result"]["moe"]

    def mark_as_complete(self, result):
        log('Uploading result: %s' % str(result))
        r = requests.post("%s://%s/experiments/%s/mark_as_complete.json" % (self.schema, self.address, self.experiment_id),
                          auth=HTTPBasicAuth(self.user, self.password),
                          params={'results': json.dumps(result)},
                          verify=self.verify)
        log(r.text)

