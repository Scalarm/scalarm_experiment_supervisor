require 'test_helper'

class SupervisorRunWatcherTest < ActiveSupport::TestCase

  DEFAULT_VALUES = {
      sleep_duration_in_seconds: 60,
      errors_limit: 5,
      is_running: false
  }

  class << SupervisorRunWatcher
    attr_accessor :sleep_duration_in_seconds, :is_running, :errors_limit
  end

  def self.create_config_entry_test(name, default_vale, new_value)
    instance_eval do
      test "proper init of #{name} when config supervisor_script_watcher entry is missing" do
        # given
        secrets = mock do
          stubs(:include?).with(:supervisor_script_watcher).returns(false)
        end
        Rails.application.stubs(:secrets).returns(secrets)
        # when
        SupervisorRunWatcher.init
        # then
        assert_equal default_vale, SupervisorRunWatcher.send(name)
      end

      test "proper init when config entry #{name} is missing" do
        # given
        secrets = mock do
          stubs(:include?).with(:supervisor_script_watcher).returns(true)
        end
        empty_entry = {}
        secrets.stubs(:supervisor_script_watcher).returns(empty_entry)
        Rails.application.stubs(:secrets).returns(secrets)
        # when
        SupervisorRunWatcher.init
        # then
        assert_equal default_vale, SupervisorRunWatcher.send(name)
      end

      test "proper init with existing config entry #{name}" do
        # given
        secrets = mock do
          stubs(:include?).with(:supervisor_script_watcher).returns(true)
        end
        entry = {name.to_s => new_value}
        secrets.stubs(:supervisor_script_watcher).returns(entry)
        Rails.application.stubs(:secrets).returns(secrets)
        # when
        SupervisorRunWatcher.init
        # then
        assert_equal new_value, SupervisorRunWatcher.send(name)
      end
    end
  end
  create_config_entry_test :sleep_duration_in_seconds, DEFAULT_VALUES[:sleep_duration_in_seconds], 30
  create_config_entry_test :errors_limit, DEFAULT_VALUES[:errors_limit], 5

  test 'proper execution of supervisor script watcher' do
    # given
    SupervisorRunWatcher.sleep_duration_in_seconds = 0
    SupervisorRunWatcher.is_running = true
    supervisor_script = mock do
      expects(:monitoring_loop!)
      stubs(:id).returns('id')
    end
    SupervisorRun.expects(:find_all_by_query)
        .with(is_running: true, is_error: false).returns([supervisor_script])
        .then.returns([])
        .twice
    # when
    SupervisorRunWatcher.watching_loop
    # then
    assert_equal false, SupervisorRunWatcher.is_running
  end

  test 'supervisor run watcher should set run into error state after several failures' do
    # given
    SupervisorRunWatcher.sleep_duration_in_seconds = 0
    is_error = states('is_error').starts_as('false')
    supervisor_script = mock do
      stubs(:id).returns('id')
      stubs(:supervisor_id).returns('id')
      stubs(:monitoring_loop!).raises(StandardError)
      expects(:set_error!).then(is_error.is('true'))
    end
    SupervisorRun.stubs(:find_all_by_query).returns([supervisor_script]).when(is_error.is('false'))
    SupervisorRun.stubs(:find_all_by_query).returns([]).when(is_error.is('true'))
    # when, then
    SupervisorRunWatcher.watching_loop
  end

  test 'watch thread should be started only once' do
    # given
    Thread.expects(:new)
    # when, then
    SupervisorRunWatcher.start_watching
    SupervisorRunWatcher.start_watching
  end

  test 'running watch thread again should be possible after ending previous thread' do
    # given
    SupervisorRun.stubs(:find_all_by_query).returns([])
    Thread.expects(:new).twice
    # when, then
    SupervisorRunWatcher.start_watching
    SupervisorRunWatcher.watching_loop
    SupervisorRunWatcher.start_watching
  end

  def teardown
    SupervisorRunWatcher.is_running = DEFAULT_VALUES[:is_running]
    SupervisorRunWatcher.sleep_duration_in_seconds = DEFAULT_VALUES[:sleep_duration_in_seconds]
    SupervisorRunWatcher.errors_limit = DEFAULT_VALUES[:errors_limit]
  end
end