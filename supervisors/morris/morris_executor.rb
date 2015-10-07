require 'supervisor_executors/abstract_supervisor_executor'

##
# Sensitivity analysis with Morris Design
# Using Sensitivity Analysis library by Daniel Bachniak, 2015
# Copyright (c) Daniel Bachniak 2015
#
# ==== Supervisor specific parameters:
# morris_samples_count::
# morris_levels_count::
#
# ==== Dependencies to run supervisor:
# [mono runtime]
# [sensitivity analysis library] should be in executables/morris/SensitivityAnalysis.dll
class MorrisExecutor < AbstractSupervisorExecutor

  BIN_DIR = 'supervisors/morris/'
  BIN_NAME = 'sensitivity_analysis.exe'

  # overrides parent method
  def self.start(config)
    experiment_id = config['experiment_id']
    script_config = config_file_path(experiment_id)
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }
    script_log = self.log_path(experiment_id).to_s
    Dir.chdir(BIN_DIR) do
      pid = Process.spawn("mono #{BIN_NAME} -config #{script_config}", out: script_log, err: script_log)
      Process.detach(pid)
      pid
    end
  end

  # overrides parent method
  def self.cleanup(experiment_id)
    files_to_delete = [self.config_file_path(experiment_id)]
    files_to_delete.each do |path|
      File.delete(path) if File.exists?(path)
    end
  end

end