require 'supervisor_executors/abstract_supervisor_executor'

class SensitivityAnalysisMorrisExecutor < AbstractSupervisorExecutor

  SCRIPT_PATH = 'supervisors/sensitivity_analysis_morris/morris.R'


  # overrides parent method
  def self.start(config)
    experiment_id = config['experiment_id']
    script_config = config_file_path(experiment_id)
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }
    script_log = self.log_path(experiment_id).to_s



    pid = Process.spawn("Rscript", SCRIPT_PATH, script_config, out: script_log, err: script_log)


    # does not find a path to file
    Process.detach(pid)
    pid
  end

  # overrides parent method
  def self.cleanup(experiment_id)
    files_to_delete = [self.log_path(experiment_id), self.config_file_path(experiment_id)]
    files_to_delete.each do |path|
      File.delete(path) if File.exists?(path)
    end
  end


end