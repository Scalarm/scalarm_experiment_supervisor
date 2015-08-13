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
end