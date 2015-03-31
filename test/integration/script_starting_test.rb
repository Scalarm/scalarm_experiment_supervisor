require 'test_helper'
require 'json'
require 'db_helper'

class ScriptStartingTest < ActionDispatch::IntegrationTest
  include DBHelper

  EXPERIMENT_ID = 'some_id'
  CONFIG_FROM_EM = {
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
  FULL_CONFIG = {
      maxiter: 1,
      dwell: 1,
      schedule: 'boltzmann',
      experiment_id: EXPERIMENT_ID,
      user: 'user',
      password: 'password',
      lower_limit: [],
      upper_limit: [],
      parameters_ids: [],
      start_point: [],
      address: EM_ADDRESS,
      http_schema: 'https'
  }
  SIMULATED_ANNEALING_ID = 'simulated_annealing'
  SCRIPT_LOG_FILE_PATH = "log/supervisor_script_log_#{EXPERIMENT_ID}"
  SCRIPT_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}"

  def setup
    information_service = InformationService.new
    information_service.expects(:get_list_of).with('experiment_managers').returns([EM_ADDRESS])
    InformationService.expects(:new).returns(information_service)
    super
  end


  test "starting simmulated annealing supervisor script" do
    assert_difference 'SupervisorScript.count', 1 do
      post start_supervisor_script_path script_id: SIMULATED_ANNEALING_ID, config: CONFIG_FROM_EM.to_json
    end
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'pid')
    end
    assert_equal response_hash['status'], 'ok'
    assert File.exists? SCRIPT_LOG_FILE_PATH
    assert File.exists? SCRIPT_CONFIG_FILE_PATH
    assert_equal FULL_CONFIG.to_json, File.read(SCRIPT_CONFIG_FILE_PATH)
    @pid = response_hash['pid']
  end

  def teardown
    File.delete SCRIPT_LOG_FILE_PATH if File.exists? SCRIPT_LOG_FILE_PATH
    File.delete SCRIPT_CONFIG_FILE_PATH if File.exists? SCRIPT_CONFIG_FILE_PATH
    `kill -9 #{@pid}` if `ps #{@pid} | wc -l` == '2'
    @pid = nil
    # super
  end


end
