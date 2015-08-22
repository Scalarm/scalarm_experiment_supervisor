require 'test_helper'
require 'mocha/test_unit'

class MorrisExecutorTest < ActiveSupport::TestCase

  # also tests if out and err streams are set to log file
  test 'morris executor start should launch mono application with config file' do
    experiment_id = 'some_experiment_id'
    pid = 'some_pid'
    config = {
        'experiment_id' => experiment_id
    }

    morris_executor = SupervisorExecutorsProvider.get('morris')

    config_path = '/tmp/supervisor_script_config_some_experiment_id_a7b22f4a946bd921'
    morris_executor.stubs(:config_file_path).
        returns(config_path)

    log_path = '/home/user/scalarm_experiment_supervisor/log/supervisor_script_some_experiment_id.log'
    morris_executor.stubs(:log_path).returns(log_path)

    # if fails, check if bin name has not been changed
    bin_name = 'sensitivity_analysis.exe'
    expected_command = /\s*mono\s+#{bin_name}\s+-config\s+#{config_path}\s*/
    streams = {out: log_path, err: log_path}

    Process.expects(:spawn).with(regexp_matches(expected_command), streams).returns(pid)
    Process.expects(:detach).with(pid)

    morris_executor.start(config)
  end


end
