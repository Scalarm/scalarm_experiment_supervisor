require 'test_helper'
require 'json'
require 'supervisor_scripts_tests_helper'

class GenericScriptStartingTest < ActionDispatch::IntegrationTest
  include SupervisorScriptsTestsHelper

  test "proper response when supervisor script id is incorrect" do
    # test
    assert_no_difference 'SupervisorScript.count' do
      post start_supervisor_script_path script_id: INCORRECT_ID, config: CONFIG_FROM_EM_SIMULATED_ANNEALING.to_json
    end
    # check if only valid response params are present with proper value
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'reason')
    end
    assert_equal response_hash['status'], 'error'
    assert_equal response_hash['reason'], "#{REASON_PREFIX} #{INCORRECT_ID_MESSAGE}"
    # check proper cleanup of redundant files
    assert_not File.exists? SIMULATED_ANNEALING_CONFIG_FILE_PATH
  end

end
