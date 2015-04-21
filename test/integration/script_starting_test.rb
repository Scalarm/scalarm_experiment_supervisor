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
  SCRIPT_LOG_FILE_PATH = "log/supervisor_script_log_#{EXPERIMENT_ID}.log"
  SCRIPT_CONFIG_FILE_PATH = "/tmp/supervisor_script_config_#{EXPERIMENT_ID}"
  SCRIPT_MAIN_FILE = 'scalarm_supervisor_scrpits/simulated_annealing/anneal.py'
  SCRIPT_LIBRARY_FILE = 'scalarm_supervisor_scrpits/simulated_annealing/scalarmapi.py'
  REASON_PREFIX = '[Experiment Supervisor]'
  REASON = 'reason'
  PID = 1234

  def setup
    super
    # mock information service
    information_service = InformationService.new
    information_service.expects(:get_list_of).with('experiment_managers').returns([EM_ADDRESS])
    InformationService.expects(:new).returns(information_service)
  end

  test "successful start of simulated annealing supervisor script" do
    # mocks
    # mock script starting with tests of proper calls
    Process.expects(:spawn).with("python2 #{SCRIPT_MAIN_FILE} #{SCRIPT_CONFIG_FILE_PATH}",
                                 out: SCRIPT_LOG_FILE_PATH, err: SCRIPT_LOG_FILE_PATH).returns(PID)
    Process.expects(:detach).with(PID)
    SupervisorScriptWatcher.expects(:start_watching)
    # test
    # check existence of sm script files
    assert File.exists? SCRIPT_MAIN_FILE
    assert File.exists? SCRIPT_LIBRARY_FILE

    assert_difference 'SupervisorScript.count', 1 do
      post start_supervisor_script_path script_id: SIMULATED_ANNEALING_ID, config: CONFIG_FROM_EM.to_json
    end
    # check if only valid response params are present with proper value
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'pid')
    end
    assert_equal response_hash['status'], 'ok'
    assert_equal response_hash['pid'], PID
    # check existence of config file and its content
    assert File.exists? SCRIPT_CONFIG_FILE_PATH
    assert_equal FULL_CONFIG, JSON.parse(File.read(SCRIPT_CONFIG_FILE_PATH))
  end

  test "proper response on error while starting script with cleanup" do
    # mocks
    # create file to test proper deletion on error
    File.open(SCRIPT_LOG_FILE_PATH, 'w+')
    # raise exception on staring supervisor script
    Process.expects(:spawn).raises(StandardError, REASON)
    # test
    assert_no_difference 'SupervisorScript.count' do
      post start_supervisor_script_path script_id: SIMULATED_ANNEALING_ID, config: CONFIG_FROM_EM.to_json
    end
    # check if only valid response params are present with proper value
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'reason')
    end
    assert_equal response_hash['status'], 'error'
    assert_equal response_hash['reason'], "#{REASON_PREFIX} #{REASON}"
    # check proper cleanup of redundant files
    assert_not File.exists? SCRIPT_CONFIG_FILE_PATH
    assert_not File.exists? SCRIPT_LOG_FILE_PATH
  end

  def teardown
    # cleanup if needed
    File.delete SCRIPT_CONFIG_FILE_PATH if File.exists? SCRIPT_CONFIG_FILE_PATH
    File.delete SCRIPT_LOG_FILE_PATH if File.exists? SCRIPT_LOG_FILE_PATH
    super
  end


end
