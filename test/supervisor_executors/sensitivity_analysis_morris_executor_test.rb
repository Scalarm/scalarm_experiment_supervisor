require 'test_helper'
require 'mocha/test_unit'

class SensitivityAnalysisMorrisExecutorTest < ActiveSupport::TestCase
  include SupervisorRunTestsHelper
  # also tests if out and err streams are set to log file
  test 'SA morris executor start should launch application with config file' do

    experiment_id = 'some_experiment_id'
    pid = 'some_pid'
    config = {
        'experiment_id' => experiment_id
    }

    sa_morris_executor = SupervisorExecutorsProvider.get('sensitivity_analysis_morris')

    config_path = '/tmp/supervisor_script_config_some_experiment_id_a7b22f4a946bd921'
    sa_morris_executor.stubs(:config_file_path).
        returns(config_path)

    log_path = '/home/user/scalarm_experiment_supervisor/log/supervisor_script_some_experiment_id.log'
    sa_morris_executor.stubs(:log_path).returns(log_path)

    # if fails, check if bin name has not been changed
    bin_name = "#{DIR}/#{SENSITIVITY_ANALYSIS_MORRIS_MAIN_FILE}"
    streams = {out: log_path, err: log_path}
    Process.expects(:spawn).with('Rscript', bin_name, config_path, streams).returns(pid)
    Process.expects(:detach).with(pid)
    sa_morris_executor.start(config)
  end


end
