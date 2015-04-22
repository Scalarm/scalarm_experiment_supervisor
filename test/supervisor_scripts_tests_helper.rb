require 'db_helper'

module SupervisorScriptsTestsHelper
  include DBHelper

  EXPERIMENT_ID = 'some_id'
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
  SIMULATED_ANNEALING_LOG_FILE_PATH = "log/supervisor_script_log_#{EXPERIMENT_ID}.log"
  SIMULATED_ANNEALING_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}"
  SIMULATED_ANNEALING_MAIN_FILE = 'supervisor_scripts/simulated_annealing/anneal.py'
  SIMULATED_ANNEALING_LIBRARY_FILE = 'supervisor_scripts/simulated_annealing/scalarmapi.py'
  REASON_PREFIX = '[Experiment Supervisor]'
  REASON = 'reason'
  PID = 1
  INCORRECT_ID = 'incorrect id'
  INCORRECT_ID_MESSAGE = 'There is no supervisor script with given id'


  def teardown
    # cleanup if needed
    File.delete SIMULATED_ANNEALING_CONFIG_FILE_PATH if File.exists? SIMULATED_ANNEALING_CONFIG_FILE_PATH
    File.delete SIMULATED_ANNEALING_LOG_FILE_PATH if File.exists? SIMULATED_ANNEALING_LOG_FILE_PATH
    super
  end

  # idiom used to include ClassMethods methods as class methods
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # all methods placed here will be class methods for class that includes SupervisorScriptsTestsHelper
    def mock_information_service
      information_service = InformationService.new
      information_service.expects(:get_list_of).with('experiment_managers').returns([EM_ADDRESS])
      InformationService.expects(:new).returns(information_service)
    end
  end

end