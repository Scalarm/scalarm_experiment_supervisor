require 'test_helper'
require 'fileutils'

class AbstractSupervisorExecutorTest < ActiveSupport::TestCase
  class SomeExecutor < AbstractSupervisorExecutor
  end

  EXPERIMENT_ID = 'Some id'

  test '_start should invoke start on successful validation' do
    config = mock 'config'

    SomeExecutor.expects(:start).once
    # just pass validation
    SomeExecutor.stubs(:validate_config_security!).with(config)

    SomeExecutor._start(config)
  end

  test '_start should raise error on insecure experiment_id' do
    config = {
        'experiment_id' => 'some\binsecure'
    }

    SomeExecutor.expects(:start).never

    assert_raises SecurityError do
      SomeExecutor._start(config)
    end
  end

  test 'experiment_id validation should pass on valid experiment_id' do
    # should just pass
    SomeExecutor.validate_experiment_id!('555b53da369ffd067f000008')
  end

  test 'log_path should return valid path' do
    experiment_id = 'test_experiment_' + SecureRandom.hex(8)
    log_path = SomeExecutor.log_path(experiment_id)
    begin
      File.open(log_path, 'a')
      assert File.exists?(log_path)
    ensure
      File.delete(log_path)
      refute File.exists?(log_path)
    end
  end

  test 'config_file_path should return valid path' do
    experiment_id = 'test_experiment_' + SecureRandom.hex(8)
    config_path = SomeExecutor.config_file_path(experiment_id)
    begin
      File.open(config_path, 'a')
      assert File.exists?(config_path)
    ensure
      File.delete(config_path)
      refute File.exists?(config_path)
    end
  end

  # Warning: in rare cases (rare means in fact "never") it can fail
  # due to randomness.
  # When fail, try invoke the test one more time.
  test 'config_file_path invoked twice should return different paths' do
    experiment_id = 'test_experiment_' + SecureRandom.hex(8)
    config_path1 = SomeExecutor.config_file_path(experiment_id)
    config_path2 = SomeExecutor.config_file_path(experiment_id)
    refute_equal config_path1, config_path2
  end

  test '_cleanup should invoke validate_experiment_id! and delete_logs before real cleanup' do
    # given
    SomeExecutor.expects(:validate_experiment_id!).with EXPERIMENT_ID
    SomeExecutor.expects(:delete_logs).with EXPERIMENT_ID
    SomeExecutor.expects(:cleanup).with EXPERIMENT_ID
    # when
    SomeExecutor._cleanup EXPERIMENT_ID
    # then
  end

  test 'delete_logs should delete log file' do
    # given
    log_path = SomeExecutor.log_path EXPERIMENT_ID
    FileUtils.touch(log_path)
    # when
    SomeExecutor.send(:delete_logs, EXPERIMENT_ID) # hack to call private method
    # then
    assert_not File.exists?(log_path), 'Log file should be deleted'
  end

end