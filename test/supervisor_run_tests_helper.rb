require 'scalarm/service_core/test_utils/db_helper'
require 'test_helper'

require 'mocha/mock'

module SupervisorRunTestsHelper
  include Scalarm::ServiceCore::TestUtils::DbHelper

  EXPERIMENT_ID = BSON::ObjectId.new.to_s
  CONFIG_FROM_EM_SIMULATED_ANNEALING = {
      maxiter: 1,
      dwell: 1,
      schedule: 'boltzmann',
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
      'maxiter' => 1,
      'dwell' => 1,
      'schedule' => 'boltzmann',
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
  SIMULATED_ANNEALING_LOG_FILE_PATH = Rails.root.join('log', "supervisor_script_#{EXPERIMENT_ID}.log").to_s
  SIMULATED_ANNEALING_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}_random"
  SIMULATED_ANNEALING_MAIN_FILE = 'supervisors/simulated_annealing/anneal.py'
  SIMULATED_ANNEALING_LIBRARY_FILE = 'supervisors/simulated_annealing/scalarmapi.py'
  REASON_PREFIX = '[Experiment Supervisor]'
  REASON = 'reason'
  PID = 1234
  INCORRECT_ID = 'incorrect id'
  INCORRECT_ID_MESSAGE = 'There is no supervisor script with given id'


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