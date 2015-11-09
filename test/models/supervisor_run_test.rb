require 'test_helper'
require 'mocha/test_unit'
require 'fileutils'
require 'scalarm/service_core/test_utils/db_helper'

class SupervisorRunTest < ActiveSupport::TestCase
  include Scalarm::ServiceCore::TestUtils::DbHelper

  PID = '123'
  MESSAGE = "Supervisor script is not running\nLast 100 lines of supervisor output:\n"
  ADDRESS = 'address'
  REASON = 'reason'
  EXPERIMENT_ID = 'some_id'
  USER = 'user'
  PASSWORD = 'password'

  def setup
    super
    @supervisor_run = SupervisorRun.new
    @experiment = stub_everything 'experiment'
  end

  test 'check methods return true when script is running' do
    @supervisor_run.pid = PID
    @supervisor_run.is_running = true

    @supervisor_run.expects(:`).with("ps #{PID}")
    system('false')
    $?.expects(:success?).returns(true)
    assert @supervisor_run.check, 'Check method should return true'
    assert @supervisor_run.is_running, 'is_running flag should not be modified'
  end

  test 'check methods return false when script is not running and set is_running to false' do
    @supervisor_run.pid = PID
    @supervisor_run.is_running = true

    @supervisor_run.expects(:`).with("ps #{PID}")
    system('false')
    $?.expects(:success?).returns(false)
    assert_not @supervisor_run.check, 'Check method should return false'
    assert @supervisor_run.is_running, 'is_running flag should not be modified'
  end

  test 'monitoring loop proper behavior when script is running' do
    @supervisor_run.is_running = true
    # mock
    @supervisor_run.expects(:check).returns(true)
    @supervisor_run.expects(:notify_error).never

    # test
    @supervisor_run.monitoring_loop
    assert @supervisor_run.is_running, 'is_running flag should be true'
  end

  test 'monitoring loop proper behavior when script is not running and experiment is completed' do
    @supervisor_run.is_running = true
    # mock
    @supervisor_run.expects(:check).returns(false)
    @supervisor_run.expects(:notify_error).with(MESSAGE)
    @supervisor_run.expects(:read_log).returns('')
    @supervisor_run.stubs(:experiment).returns(@experiment)
    @experiment.stubs(:completed).returns(false)
    @supervisor_run.expects(:move_log)

    # test
    @supervisor_run.monitoring_loop
    assert_not @supervisor_run.is_running, 'is_running flag should be false'
  end

  test 'do not notify error when script is not running and experiment is completed' do
    @supervisor_run.is_running = true
    # mock
    @supervisor_run.expects(:check).returns(false)
    @supervisor_run.expects(:notify_error).never
    @supervisor_run.stubs(:experiment).returns(@experiment)
    @experiment.stubs(:completed).returns(true)
    @supervisor_run.expects(:move_log)

    # test
    @supervisor_run.monitoring_loop
    assert_not @supervisor_run.is_running, 'is_running flag should be false'
  end

  test 'monitoring loop should raise exception when script is not running' do
    e = assert_raises RuntimeError do
      @supervisor_run.monitoring_loop
    end
    assert_equal e.to_s, 'Tried to check supervisor script executor state, but it is not running'
  end

  test 'proper behavior of notify error' do
    @supervisor_run.experiment_id = EXPERIMENT_ID
    @supervisor_run.experiment_manager_credentials = {'user' => USER, 'password' => PASSWORD}
    # mocks
    information_service = mock 'InformationService'
    information_service.expects(:sample_public_url).with('experiment_managers').returns(ADDRESS)
    InformationService.expects(:instance).returns(information_service)

    RestClient::Request.expects(:execute).with(
        method: :post,
        url: "https://#{ADDRESS}/experiments/#{EXPERIMENT_ID}/mark_as_complete.json",
        payload: {status: 'error', reason: REASON},
        user: USER,
        password: PASSWORD,
        verify_ssl: false
    ).returns({status: 'ok'}.to_json)

    # test
    @supervisor_run.notify_error REASON
  end

  test 'proper behavior of notify error when there is no available experiment manager' do
    @supervisor_run.experiment_id = EXPERIMENT_ID
    @supervisor_run.experiment_manager_credentials = {'user' => USER, 'password' => PASSWORD}
    # mocks
    information_service = mock 'InformationService'
    information_service.expects(:sample_public_url).with('experiment_managers').returns(nil)
    InformationService.expects(:instance).returns(information_service)

    RestClient::Request.expects(:execute).never

    # test
    @supervisor_run.notify_error REASON
  end

  FILE_PATH = '/tmp/test.txt'

  test 'proper behavior od read_log method when lines number is greater than 100' do
    @supervisor_run.expects(:log_path).returns(FILE_PATH)

    File.open(FILE_PATH, 'w+') do |file|
      (1..101).each {|x| file.write("#{x}\n")}
    end
    assert_equal @supervisor_run.read_log, "#{(2..101).to_a.join("\n")}\n"
    File.delete(FILE_PATH)
  end

  test 'proper behavior od read_log method when lines number is lower than 100' do
    @supervisor_run.expects(:log_path).returns(FILE_PATH)

    File.open(FILE_PATH, 'w+') do |file|
      (1..99).each {|x| file.write("#{x}\n")}
    end
    assert_equal @supervisor_run.read_log, "#{(1..99).to_a.join("\n")}\n"
    File.delete(FILE_PATH)
  end

  test 'proper behavior od read_log method when lines number is equal 100' do
    @supervisor_run.expects(:log_path).returns(FILE_PATH)

    File.open(FILE_PATH, 'w+') do |file|
      (1..100).each {|x| file.write("#{x}\n")}
    end
    assert_equal @supervisor_run.read_log, "#{(1..100).to_a.join("\n")}\n"
    File.delete(FILE_PATH)
  end

  test 'proper behavior od read_log method on file reading error' do
    @supervisor_run.expects(:log_path).times(3).returns(FILE_PATH)
    IO.expects(:readlines).with(FILE_PATH).throws(StandardError)
    assert_equal @supervisor_run.read_log, "Unable to load log file: #{FILE_PATH}"
  end

  test 'proper behaviour of stop method with stubborn process' do
    @supervisor_run.pid = PID
    @supervisor_run.is_running = true
    @supervisor_run.expects(:check).returns(true).twice
    Process.expects(:kill).with('TERM', PID)
    Process.expects(:kill).with('KILL', PID)

    @supervisor_run.stop

    assert_equal false, @supervisor_run.is_running
  end

  test 'proper behaviour of stop method with cooperating process' do
    @supervisor_run.pid = PID
    @supervisor_run.is_running = true
    @supervisor_run.expects(:check).returns(true).then.returns(false).twice
    Process.expects(:kill).with('TERM', PID)

    @supervisor_run.stop

    assert_equal false, @supervisor_run.is_running
  end


  test 'proper behaviour of destroy method when script is not running' do
    @supervisor_run.expects(:check).returns(false)
    @supervisor_run.save

    assert_difference 'SupervisorRun.count', -1 do
      @supervisor_run.destroy
    end
  end

  test 'proper behaviour of destroy method when script is running' do
    @supervisor_run.expects(:check).returns(true)
    @supervisor_run.expects(:stop)
    @supervisor_run.save

    assert_difference 'SupervisorRun.count', -1 do
      @supervisor_run.destroy
    end
  end

  STATE_ALLOWED_KEYS = [:experiment_id, :supervisor_id, :pid, :is_running, :supervisor_run_id, :user_id,
                        :is_error, :reason]

  test 'state returns all and only allowed keys' do
    SupervisorRun::STATE_ALLOWED_KEYS.each {|key| @supervisor_run.send("#{key}=".to_sym, 'val')}
    @supervisor_run.forbidden_key = 'val'

    state = @supervisor_run.state
    assert_nothing_raised do
      state.assert_valid_keys(STATE_ALLOWED_KEYS)
    end
    STATE_ALLOWED_KEYS.each {|key| assert state.has_key?(key), "State should contains key #{key}"}
  end

  ARCHIVE_LOG_PATH='/tmp/'

  test 'move_log should move log when log file exists and config entry is present' do
    # given
    original_log_file_path = AbstractSupervisorExecutor.log_path EXPERIMENT_ID
    new_log_file_path = ARCHIVE_LOG_PATH + AbstractSupervisorExecutor.log_file_name(EXPERIMENT_ID)
    FileUtils.touch(original_log_file_path)
    @supervisor_run.stubs(:experiment_id).returns(EXPERIMENT_ID)
    secrets = mock do
      stubs(:include?).with(:log_archive_path).returns(true)
      stubs(:log_archive_path).returns(ARCHIVE_LOG_PATH)
    end
    Rails.application.stubs(:secrets).returns(secrets)
    # when
    @supervisor_run.send(:move_log) # hack to call private method
    # then
    assert_not File.exists?(original_log_file_path), 'File should be moved to proper location'
    assert File.exists?(new_log_file_path), 'File should be moved to proper location'
    # cleanup
    remove_file_if_exists original_log_file_path
    remove_file_if_exists new_log_file_path
  end

  test 'move_log should not move log when log file not exists' do
    # given
    original_log_file_path = AbstractSupervisorExecutor.log_path EXPERIMENT_ID
    remove_file_if_exists original_log_file_path
    new_log_file_path = ARCHIVE_LOG_PATH + AbstractSupervisorExecutor.log_file_name(EXPERIMENT_ID)
    @supervisor_run.stubs(:experiment_id).returns(EXPERIMENT_ID)
    secrets = mock do
      stubs(:include?).with(:log_archive_path).returns(true)
    end
    Rails.application.stubs(:secrets).returns(secrets)
    # when
    @supervisor_run.send(:move_log) # hack to call private method
    # then
    assert_not File.exists?(new_log_file_path), 'Log file should not exist'
    # cleanup
    remove_file_if_exists new_log_file_path
  end

  test 'move_log should not move log when config entry is not present' do
    # given
    original_log_file_path = AbstractSupervisorExecutor.log_path EXPERIMENT_ID
    new_log_file_path = ARCHIVE_LOG_PATH + AbstractSupervisorExecutor.log_file_name(EXPERIMENT_ID)
    FileUtils.touch(original_log_file_path)
    @supervisor_run.stubs(:experiment_id).returns(EXPERIMENT_ID)
    secrets = mock do
      stubs(:include?).with(:log_archive_path).returns(false)
    end
    Rails.application.stubs(:secrets).returns(secrets)
    # when
    @supervisor_run.send(:move_log) # hack to call private method
    # then
    assert File.exists?(original_log_file_path), 'File should not be moved'
    assert_not File.exists?(new_log_file_path), 'File should not be moved'
    # cleanup
    remove_file_if_exists original_log_file_path
    remove_file_if_exists new_log_file_path
  end

  NOT_EXISTING_DIRECTORY = '/foo/bar/baz/'

  test 'move_log should not fail when archive file path not exist' do
    # given
    original_log_file_path = AbstractSupervisorExecutor.log_path EXPERIMENT_ID
    new_log_file_path = NOT_EXISTING_DIRECTORY + AbstractSupervisorExecutor.log_file_name(EXPERIMENT_ID)
    FileUtils.touch(original_log_file_path)
    @supervisor_run.stubs(:experiment_id).returns(EXPERIMENT_ID)
    secrets = mock do
      stubs(:include?).with(:log_archive_path).returns(true)
      stubs(:log_archive_path).returns(NOT_EXISTING_DIRECTORY)
    end
    Rails.application.stubs(:secrets).returns(secrets)
    # when
    @supervisor_run.send(:move_log) # hack to call private method
    # then
    assert File.exists?(original_log_file_path), 'File should not be moved'
    assert_not File.exists?(new_log_file_path), 'File should not be moved'
    # cleanup
    remove_file_if_exists original_log_file_path
    remove_file_if_exists new_log_file_path
  end

  test 'set_error should put run in error state and stop execution' do
    # given
    @supervisor_run.is_error = false
    @supervisor_run.stubs(:check).returns(true)
    @supervisor_run.stubs(:read_log).returns('')
    @supervisor_run.expects(:stop)
    @supervisor_run.expects(:notify_error)
    # when
    @supervisor_run.set_error(REASON)
    # then
    assert_equal REASON, @supervisor_run.reason
    assert_equal true, @supervisor_run.is_error
  end

  test 'declare_persistent_method should create persistent method version' do
    # given
    SupervisorRun.declare_persistent_method :test
    @supervisor_run.expects(:test).with(:foo, :bar).returns(:bar)
    @supervisor_run.expects(:save)
    # when, then
    assert_equal :bar, @supervisor_run.test!(:foo, :bar)
  end

end
