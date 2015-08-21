require 'test_helper'

class AbstractSupervisorExecutorTest < ActiveSupport::TestCase
  class SomeExecutor < AbstractSupervisorExecutor
  end

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

end