require 'test_helper'
require 'mocha/test_unit'

class SupervisorScriptTest < ActiveSupport::TestCase

  PID = '123'
  MESSAGE = 'Supervisor script is not running'
  ADDRESS = 'address'
  REASON = 'reason'
  EXPERIMENT_ID = 'some_id'
  USER = 'user'
  PASSWORD = 'password'

  def setup
    @supervisor_script = SupervisorScript.new({})
  end

  test "check methods return true when script is running" do
    @supervisor_script.pid = PID

    @supervisor_script.expects(:`).with("ps #{PID} | wc -l").returns('2')
    assert @supervisor_script.check, 'Check method should return true'
  end

  test "check methods return false when script is not running and set is_running to false" do
    @supervisor_script.pid = PID
    @supervisor_script.is_running = true

    @supervisor_script.expects(:`).with("ps #{PID} | wc -l").returns('1')
    assert_not @supervisor_script.check, 'Check method should return false'
    assert_not @supervisor_script.is_running, 'is_running flag should be false'
  end

  test "monitoring loop proper behavior when script is running" do
    @supervisor_script.is_running = true
    # mock
    @supervisor_script.expects(:check).returns(true)
    @supervisor_script.expects(:notify_error).never

    # test
    @supervisor_script.monitoring_loop
  end

  test "monitoring loop proper behavior when script is not running" do
    @supervisor_script.is_running = true
    # mock
    @supervisor_script.expects(:check).returns(false)
    @supervisor_script.expects(:notify_error).with(MESSAGE)

    # test
    @supervisor_script.monitoring_loop
  end

  test "monitoring loop should raise exception when script is not running" do
    e = assert_raises RuntimeError do
      @supervisor_script.monitoring_loop
    end
    assert_equal e.to_s, 'Supervisor script is not running'
  end

  test "proper behavior of notify error" do
    @supervisor_script.experiment_id = EXPERIMENT_ID
    @supervisor_script.experiment_manager_credentials = {'user' => USER, 'password' => PASSWORD}
    # mocks
    information_service = mock()
    information_service.expects(:get_list_of).with('experiment_managers').returns([ADDRESS])
    InformationService.expects(:new).returns(information_service)

    RestClient::Request.expects(:execute).with(
        method: :post,
        url: "https://#{ADDRESS}/experiments/#{EXPERIMENT_ID}/mark_as_complete.json",
        payload: {status: 'error', reason: REASON},
        user: USER,
        password: PASSWORD,
        verify_ssl: false
    ).returns({status: 'ok'}.to_json)

    # test
    @supervisor_script.notify_error REASON
  end

  test "proper behavior of notify error when there is no available experiment manager" do
    @supervisor_script.experiment_id = EXPERIMENT_ID
    @supervisor_script.experiment_manager_credentials = {'user' => USER, 'password' => PASSWORD}
    # mocks
    information_service = mock()
    information_service.expects(:get_list_of).with('experiment_managers').returns([])
    InformationService.expects(:new).returns(information_service)

    RestClient::Request.expects(:execute).never

    # test
    @supervisor_script.notify_error REASON
  end
end
