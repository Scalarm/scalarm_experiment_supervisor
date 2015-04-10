require 'test_helper'
require 'supervisor_scripts_tests_helper'

class SimulatedAnnealingStartingTest < ActionDispatch::IntegrationTest
  include SupervisorScriptsTestsHelper

  test "successful start of simulated annealing supervisor script" do
    # mocks
    self.class.mock_information_service
    # mock script starting with tests of proper calls
    Process.expects(:spawn).with("python2 #{SIMULATED_ANNEALING_MAIN_FILE} #{SIMULATED_ANNEALING_CONFIG_FILE_PATH}",
                                 out: SIMULATED_ANNEALING_LOG_FILE_PATH, err: SIMULATED_ANNEALING_LOG_FILE_PATH).returns(PID)
    Process.expects(:detach).with(PID)
    # test
    # check existence of sm script files
    assert File.exists? SIMULATED_ANNEALING_MAIN_FILE
    assert File.exists? SIMULATED_ANNEALING_LIBRARY_FILE

    assert_difference 'SupervisorScript.count', 1 do
      post start_supervisor_script_path script_id: SIMULATED_ANNEALING_ID, config: CONFIG_FROM_EM_SIMULATED_ANNEALING.to_json
    end
    # check if only valid response params are present with proper value
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'pid')
    end
    assert_equal response_hash['status'], 'ok'
    assert_equal response_hash['pid'], PID
    # check existence of config file and its content
    assert File.exists? SIMULATED_ANNEALING_CONFIG_FILE_PATH
    assert_equal FULL_CONFIG_SIMULATED_ANNEALING, JSON.parse(File.read(SIMULATED_ANNEALING_CONFIG_FILE_PATH))
  end

  test "proper response on error while starting simmulated annealing script with cleanup" do
    # mocks
    self.class.mock_information_service
    # create file to test proper deletion on error
    File.open(SIMULATED_ANNEALING_LOG_FILE_PATH, 'w+')
    # raise exception on staring supervisor script
    Process.expects(:spawn).raises(StandardError, REASON)
    # test
    assert_no_difference 'SupervisorScript.count' do
      post start_supervisor_script_path script_id: SIMULATED_ANNEALING_ID, config: CONFIG_FROM_EM_SIMULATED_ANNEALING.to_json
    end
    # check if only valid response params are present with proper value
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'reason')
    end
    assert_equal response_hash['status'], 'error'
    assert_equal response_hash['reason'], "#{REASON_PREFIX} #{REASON}"
    # check proper cleanup of redundant files
    assert_not File.exists? SIMULATED_ANNEALING_CONFIG_FILE_PATH
    assert_not File.exists? SIMULATED_ANNEALING_LOG_FILE_PATH
  end
end
