require 'scalarm/service_core/test_utils/db_helper'
require 'test_helper'

require 'mocha/mock'

module SupervisorRunTestsHelper
  include Scalarm::ServiceCore::TestUtils::DbHelper

  PYTHONPATH = 'lib/api_clients/python2:.'

  EXPERIMENT_ID = BSON::ObjectId.new.to_s
  CONFIG_FROM_EM_SIMULATED_ANNEALING = {
      initial_temperature: 1000,
      cooling_rate: 0.001,
      points_limit: 0,
      dwell: 10,
      spread: 10,
      experiment_id: EXPERIMENT_ID,
      user: 'user',
      password: 'password',
      lower_limit: [],
      upper_limit: [],
      parameters_ids: [],
      start_point: []
  }
  EM_ADDRESS = 'none'
  FULL_CONFIG_SIMULATED_ANNEALING = {
      'initial_temperature' => 1000,
      'cooling_rate' => 0.001,
      'points_limit' => 0,
      'dwell' => 10,
      'spread' => 10,
      'experiment_id' => EXPERIMENT_ID,
      'user' => 'user',
      'password' => 'password',
      'lower_limit' => [],
      'upper_limit' => [],
      'parameters_ids' => [],
      'start_point' => [],
      'address' => EM_ADDRESS,
      'http_schema' => 'https'
  }
  SIMULATED_ANNEALING_ID = 'simulated_annealing'
  SIMULATED_ANNEALING_LOG_FILE_PATH = Rails.root.join('log', 'supervisors', "supervisor_script_#{EXPERIMENT_ID}.log").to_s
  SIMULATED_ANNEALING_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}_random"
  SIMULATED_ANNEALING_MAIN_FILE = 'supervisors/simulated_annealing/anneal.py'
  SIMULATED_ANNEALING_LIBRARY_FILE = 'lib/api_clients/python2/scalarmapi.py'
  REASON_PREFIX = '[Experiment Supervisor]'
  REASON = 'reason'
  PID = 1234
  INCORRECT_ID = 'incorrect id'
  INCORRECT_ID_MESSAGE = 'There is no supervisor script with given id'

  CONFIG_FROM_EM_SENSITIVITY_ANALAYSIS_MORRIS =
      {
          supervisor_script_id: "sensitivity_analysis_morris",
          type:"supervised",
          supervisor_script_params:"",
          design_type:"oat",
          size:1,
          gridjump:1,
          levels:1,
          factor:1,
          experiment_id: EXPERIMENT_ID,
          user: "user",
          password:"password",
          parameters:[
              {
                  id:"parameter1",
                  type:"integer",
                  min:0,
                  max:1000,
                  start_value:500
              },
              {
                  id:"parameter2",
                  type:"integer",
                  min:-100,
                  max:100,
                  start_value:0
              }
          ],
          address:"localhost:3001",
          http_schema:"https"
      }

  FULL_CONFIG_SENSITIVITY_ANALAYSIS_MORRIS ={
          "supervisor_script_id"=>"sensitivity_analysis_morris",
          "type"=>"supervised",
          "supervisor_script_params"=>"",
          "design_type"=>"oat",
          "size"=>1,
          "gridjump"=>1,
          "levels"=>1,
          "factor"=>1,
          "experiment_id"=>EXPERIMENT_ID,
          "user" =>"user",
          "password"=>"password",
          "parameters"=>[
              {
                  "id"=>"parameter1",
                  "type"=>"integer",
                  "min"=>0,
                  "max"=>1000,
                  "start_value"=>500
              },
              {
                  "id"=>"parameter2",
                  "type"=>"integer",
                  "min"=>-100,
                  "max"=>100,
                  "start_value"=>0
              }
          ],
          "address"=>EM_ADDRESS,
          "http_schema"=>"https"
  }

  SENSITIVITY_ANALYSIS_ID = 'sensitivity_analysis_morris'
  SENSITIVITY_ANALYSIS_LOG_FILE_PATH = Rails.root.join('log', 'supervisors', "supervisor_script_#{EXPERIMENT_ID}.log").to_s
  SENSITIVITY_ANALYSIS_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}_random"
  SENSITIVITY_ANALYSIS_MORRIS_MAIN_FILE = 'supervisors/sensitivity_analysis_morris/morris.R'
  SENSITIVITY_ANALYSIS_LIBRARY_FILE = 'supervisors/sensitivity_analysis_morris/scalarmapi.R'
  DIR = File.dirname(__FILE__).match("(.*)/test").captures[0].to_s
  def teardown
    # cleanup if needed
    remove_file_if_exists SIMULATED_ANNEALING_CONFIG_FILE_PATH
    remove_file_if_exists SIMULATED_ANNEALING_LOG_FILE_PATH
    super
  end

  # idiom used to include ClassMethods methods as class methods
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # all methods placed here will be class methods for class that includes SupervisorScriptsTestsHelper
    def mock_information_service
      information_service = Mocha::Mock.new 'InformationService'
      information_service.expects(:get_list_of).with('experiment_managers').returns([EM_ADDRESS])
      InformationService.expects(:instance).returns(information_service)
    end
  end

end