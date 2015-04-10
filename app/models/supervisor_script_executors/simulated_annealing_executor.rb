require_relative 'abstract_supervisor_script_executor'

=begin
  @api {post} /start_supervisor_script.json Simulated Annealing Parameters
  @apiName start_simulated_annealing
  @apiGroup SupervisorScripts
  @apiDescription Description of parameters needed to star simulated annealing.
    Description of generic method params is in start_supervisor_script entry.

  @apiParam {String} script_id ID of simulated annealing = 'simulated_annealing'
  @apiParam {Object} config json Object with config of simulated annealing
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
      Other parameters needed in star_supervisor_script method
    */
  }

=end
class SimulatedAnnealingExecutor < AbstractSupervisorScriptExecutor

  SCRIPT_PATH = 'scalarm_supervisor_scrpits/simulated_annealing/anneal.py'
  LOG_FILE_PREFIX = 'log/supervisor_script_log_'
  LOG_FILE_SUFFIX = '.log'
  CONFIG_FILE_PREFIX = '/tmp/supervisor_script_config_'

  # overrides parent method
  # * Creates config file in /tmp/supervisor_script_config_<experiment_id>
  # * Starts simulated annealing script with output set to log/supervisor_script_log_<experiment_id>.log
  def self.start(config)
    script_config = "#{CONFIG_FILE_PREFIX}#{config['experiment_id']}"
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }

    script_log = "#{LOG_FILE_PREFIX}#{config['experiment_id']}#{LOG_FILE_SUFFIX}"

    pid = Process.spawn("python2 #{SCRIPT_PATH} #{script_config}", out: script_log, err: script_log)
    Process.detach(pid)
    pid
  end

  # overrides parent method
  def self.cleanup(experiment_id)
    if File.exists? "#{LOG_FILE_PREFIX}#{experiment_id}#{LOG_FILE_SUFFIX}"
      File.delete "#{LOG_FILE_PREFIX}#{experiment_id}#{LOG_FILE_SUFFIX}"
    end
    File.delete "#{CONFIG_FILE_PREFIX}#{experiment_id}" if File.exists? "#{CONFIG_FILE_PREFIX}#{experiment_id}"
  end
end