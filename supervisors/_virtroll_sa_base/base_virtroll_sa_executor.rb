##
# Sensitivity analysis with Morris Design
# Using Sensitivity Analysis library by Daniel Bachniak, 2015
# Copyright (c) Daniel Bachniak 2015
#
# ==== Dependencies to run supervisor:
# [mono runtime]
# [sensitivity analysis library] should be in executables/virtroll_sa_morris/SensitivityAnalysis.dll
module BaseVirtrollSaExecutor

  BIN_DIR = 'bin/virtroll_sa/'
  BIN_NAME = 'sensitivity_analysis.exe'

  def start(config)
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

  def cleanup(experiment_id)
    files_to_delete = [self.config_file_path(experiment_id)]
    files_to_delete.each do |path|
      File.delete(path) if File.exists?(path)
    end
  end

end