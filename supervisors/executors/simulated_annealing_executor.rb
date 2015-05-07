require 'supervisor_executors/abstract_supervisor_executor'

=begin
  @api {post} /start_supervisor_script.json Simulated Annealing Parameters
  @apiName start_simulated_annealing
  @apiGroup SupervisorScripts
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

  SCRIPT_PATH = 'supervisors/executables/simulated_annealing/anneal.py'
  CONFIG_FILE_PREFIX = '/tmp/supervisor_script_config_'

  # overrides parent method
  def self.start(config)
    script_config = "#{CONFIG_FILE_PREFIX}#{config['experiment_id']}"
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }
    script_log = self.log_path(config['experiment_id']).to_s
    pid = Process.spawn("python2 #{SCRIPT_PATH} #{script_config}", out: script_log, err: script_log)
    Process.detach(pid)
    pid
  end

  # overrides parent method
  def self.cleanup(experiment_id)
    File.delete self.log_path(experiment_id) if File.exists? self.log_path(experiment_id)
    File.delete "#{CONFIG_FILE_PREFIX}#{experiment_id}" if File.exists? "#{CONFIG_FILE_PREFIX}#{experiment_id}"
  end
end