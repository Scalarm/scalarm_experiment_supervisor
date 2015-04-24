require 'test_helper'

class SupervisorScriptWatcherTest < ActiveSupport::TestCase

  VALUE = 30
  DEFAULT_VALUE = 60

  test "proper init when config supervisor_script_watcher entry is missing" do
    secrets = mock()
    secrets.expects(:include?).with(:supervisor_script_watcher).returns(false)
    Rails.application.expects(:secrets).returns(secrets)
    SupervisorScriptWatcher.init
    assert_equal SupervisorScriptWatcher.class_eval {class_variable_get :@@sleep_duration_in_seconds}, DEFAULT_VALUE
  end

  test "proper init when config sleep_duration_in_seconds entry is missing" do
    secrets = mock()
    secrets.expects(:include?).with(:supervisor_script_watcher).returns(true)
    empty_entry = {}
    secrets.expects(:supervisor_script_watcher).returns(empty_entry)

    Rails.application.expects(:secrets).returns(secrets).twice
    SupervisorScriptWatcher.init
    assert_equal SupervisorScriptWatcher.class_eval {class_variable_get :@@sleep_duration_in_seconds}, DEFAULT_VALUE
  end

  test "proper init with config config value" do
    secrets = mock()
    secrets.expects(:include?).with(:supervisor_script_watcher).returns(true)
    entry = {"sleep_duration_in_seconds" => VALUE}
    secrets.expects(:supervisor_script_watcher).returns(entry).twice

    Rails.application.expects(:secrets).returns(secrets).times 3
    SupervisorScriptWatcher.init
    assert_equal SupervisorScriptWatcher.class_eval {class_variable_get :@@sleep_duration_in_seconds}, VALUE
  end

  test "proper execution of supervisor script watcher" do
    # mocks
    SupervisorScriptWatcher.class_eval {class_variable_set :@@sleep_duration_in_seconds, 1}

    supervisor_script = mock()
    supervisor_script.expects(:save)
    supervisor_script.expects(:monitoring_loop)

    SupervisorScript.expects(:find_all_by_query).with(is_running: true)
        .returns([supervisor_script]).then.returns([]).twice

    # test
    SupervisorScriptWatcher.watching_loop
  end

  test "watch thread should be started only once" do
    Thread.expects(:new)
    SupervisorScriptWatcher.start_watching
    SupervisorScriptWatcher.start_watching
  end

  test "running watch thread again should be possible after ending previous thread" do
    SupervisorScript.expects(:find_all_by_query).with(is_running: true).returns([])
    Thread.expects(:new).twice
    SupervisorScriptWatcher.start_watching
    SupervisorScriptWatcher.watching_loop
    SupervisorScriptWatcher.start_watching
  end

  def teardown
    SupervisorScriptWatcher.class_eval {class_variable_set :@@is_running, false}
    SupervisorScriptWatcher.class_eval {class_variable_set :@@sleep_duration_in_seconds, 60}
  end
end