##
# Optimization
# Using optimization library for VirtRoll project
#
# ==== Dependencies to run supervisor:
# - mono runtime
# - binaries in ``<rails_app_root>/bin/virtoll_optimization`` - see README.md for details
module BaseVirtrollOptimizationExecutor

  BIN_DIR = 'bin/virtroll_optimization/'
  BIN_NAME = 'VirtrollOptimization.exe'

  def start(config)
    experiment_id = config['experiment_id']
    script_config = config_file_path(experiment_id)
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }
    script_log = self.log_path(experiment_id).to_s
    Dir.chdir(BIN_DIR) do
      cmd = "mono #{BIN_NAME} -config #{script_config}"
      Rails.logger.info("Starting VirtRoll optimization executor with command: #{cmd}")
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