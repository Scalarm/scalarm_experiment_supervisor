require 'test_helper'
require 'json'

class ScriptStartingTest < ActionDispatch::IntegrationTest
  test "starting simmulated annealing supervisor script" do
    post start_supervisor_script_path script_id: simulated_annealing_id,
                                      config: simulated_annealing_correct_params
    response_hash = JSON.parse(response.body)
    assert_nothing_raised do
      response_hash.assert_valid_keys('status', 'pid')
    end
    assert_equal response_hash['status'], 'ok'
    assert_equal 1, SupervisorScript.count
    assert File.exists? script_log_file_path
    assert File.exists? script_config_file_path
    assert_equal simulated_annealing_correct_params, File.read(script_config_file_path)
    @pid = response_hash['pid']
  end

  def teardown
    File.delete script_log_file_path if File.exists? script_log_file_path
    File.delete script_config_file_path if File.exists? script_config_file_path
    `kill -9 #{@pid}` if `ps #{@pid} | wc -l` == 2
    @pid = nil
    super
  end


end
