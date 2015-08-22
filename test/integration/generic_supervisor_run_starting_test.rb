require 'test_helper'
require 'json'
require 'supervisor_run_tests_helper'

class GenericSupervisorRunStartingTest < ActionDispatch::IntegrationTest
  include SupervisorRunTestsHelper
  ID = 'id'
  CONFIG = {'experiment_id' => EXPERIMENT_ID}

  def setup
    super
    stub_authentication
    @user_id = @user.id
    experiment = mock do
      stubs(:user_id).returns(@user_id)
      stubs(:shared_with).returns([])
    end
    Scalarm::Database::Model::Experiment.stubs(:where).returns([experiment])
  end

  test "proper response when supervisor script id is incorrect" do
    # test
    assert_no_difference 'SupervisorRun.count' do
      post supervisor_runs_path supervisor_id: INCORRECT_ID, config: CONFIG_FROM_EM_SIMULATED_ANNEALING.to_json
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

  test "id should be recognized as supervisor_id" do
    supervisor_run = mock do
      expects(:start).with(ID, CONFIG['experiment_id'], @user_id, CONFIG).returns(1)
      expects(:save)
      expects(:id).returns(ID)
    end
    SupervisorRun.expects(:new).with({}).returns(supervisor_run)

    post create_run_supervisor_path(ID), config: CONFIG.to_json

  end

end
