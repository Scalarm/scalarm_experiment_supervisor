require 'supervisor_executors/abstract_supervisor_executor'

=begin
apiDoc:
  @api {get} /supervisors New SupervisorRun view
  @apiName supervisor_runs#new
  @apiGroup SupervisorRuns
  @apiDescription Description of parameters needed to start simulated annealing.
    Description of generic method params is in start_supervisor_script entry.

  @apiParam {String} script_id ID of simulated annealing = 'simulated_annealing'
  @apiParam {Object} config json object with config of simulated annealing
  @apiParam {Number} config.maxiter Maximum number of iterations
  @apiParam {Number} config.dwell Value of dwell parameter
  @apiParam {String} config.schedule Scheduling method

  @apiParamExample Params-Example
  script_id: 'simulated_annealing'
  config:
  {
    maxiter: 1,
    dwell: 1,
    schedule: 'boltzmann',
    /*
      Other parameters needed in start_supervisor_script method
    */
  }

=end
class SimulatedAnnealingExecutor < AbstractSupervisorExecutor

  SCRIPT_PATH = 'supervisors/simulated_annealing/anneal.py'

  # overrides parent method
  def self.start(config)
    experiment_id = config['experiment_id']
    script_config = config_file_path(experiment_id)
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }
    script_log = self.log_path(experiment_id).to_s
    pid = Process.spawn({'PYTHONPATH'=>'lib/api_clients/python2:.'}, 'python2', SCRIPT_PATH, script_config, out: script_log, err: script_log)
    Process.detach(pid)
    pid
  end

  # overrides parent method
  def self.cleanup(experiment_id)
    files_to_delete = [self.config_file_path(experiment_id)]
    files_to_delete.each do |path|
      File.delete(path) if File.exists?(path)
    end
  end


end