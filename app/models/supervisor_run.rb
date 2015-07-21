require 'supervisor_executors/supervisor_executors_provider'

require 'scalarm/database/core/mongo_active_record'
require 'scalarm/database/model/experiment'

Dir[Rails.root.join('supervisors', '*', '*_executor.rb').to_s].each {|file| require file}

# TODO: maybe move model to scalarm-database

##
# This class represents an instance of one supervisor script and maintains
# its creation, monitoring and deletion.
#
# List of possible attributes:
# * experiment_id - id of experiment that is supervised by script (set by #start method)
# * supervisor_id - id of supervisor, specify which script is used for supervising (set by #start
#   method)
# * pid - pid of supervisor script process (set by #start method)
# * is_running - true when supervisor script is running, false otherwise (set by #start, modified by #monitoring_loop, #stop)
# * experiment_manager_credentials - hash with credentials to experiment manager (set by #start):
#   * user
#   * password
# TODO: I think we should add simulation_manager_temp_password_id to avoid redundancy
class SupervisorRun < Scalarm::Database::MongoActiveRecord
  use_collection 'supervisor_runs'

  attr_join :experiment, Scalarm::Database::Model::Experiment

  PROVIDER = SupervisorExecutorsProvider
  STATE_ALLOWED_KEYS = %w(supervisor_id user_id experiment_id pid is_running)

  ##
  # Starts new supervised script by using proper executor
  #
  # Required params
  # * id - id of supervisor script
  # * config - json with config for supervisor script (config is not validated)
  # Returns
  # * pid of started script
  # Raises
  # * Various StandardError exceptions caused by creating file or starting process.
  def start(id, experiment_id, user_id, config)
    raise 'There is no supervisor script with given id' unless PROVIDER.has_key? id
    self.supervisor_id = id
    self.user_id = user_id
    self.experiment_id = experiment_id
    self.experiment_manager_credentials = {user: config['user'], password: config['password']}
    # TODO validate config
    information_service = InformationService.instance
    config['address'] = information_service.get_list_of('experiment_managers').sample
    config['http_schema'] = 'https' # TODO - temporary, change to config entry
    self.pid = PROVIDER.get(id).start config
    Rails.logger.info "New supervisor run for #{id}, pid: #{self.pid}"
    self.is_running = true
    SupervisorRunWatcher.start_watching
    self.pid
  end

  ##
  # Returns log_path for given supervisor script
  def log_path
    PROVIDER.get(self.supervisor_id).log_path(self.experiment_id.to_s)
  end

  ##
  # Checks if supervisor script is running
  def check
    return false unless self.pid
    `ps #{self.pid}`
    unless $?.success?
      Rails.logger.info "Supervisor script is not running anymore: #{self.id}"
      return false
    end
    true
  end

  ##
  # This method notifies error with supervisor script to experiment manager.
  # Execution of this action will put experiment to error state
  def notify_error(reason)
    Rails.logger.info("Will notify error to ExperimentManager: #{reason}")
    begin
      information_service = InformationService.instance
      address = information_service.sample_public_url('experiment_managers')
      raise 'There is no available experiment manager instance' if address.nil?
      schema = 'https' # TODO - temporary, change to config entry

      Rails.logger.debug "Connecting to experiment manager on #{address}"
      res = RestClient::Request.execute(
          method: :post,
          url: "#{schema}://#{address}/experiments/#{self.experiment_id.to_s}/mark_as_complete.json",
          payload: {status: 'error', reason: reason},
          user: self.experiment_manager_credentials['user'],
          password: self.experiment_manager_credentials['password'],
          verify_ssl: false
      )
      Rails.logger.debug "Experiment manager response: #{res}"
      raise 'Error while sending error message' if JSON.parse(res)['status'] != 'ok'
    rescue RestClient::Exception, StandardError => e
      Rails.logger.info "Unable to connect with experiment manager, please contact administrator: #{e.to_s}"
    end
  end

  ##
  # Returns last 100 lines of script log
  def read_log
    begin
      log = IO.readlines(log_path)
      log = log[-100..-1] if log.size > 100
      log.join
    rescue => e
      Rails.logger.debug "Unable to load log file: #{log_path}\n#{e.to_s}"
      "Unable to load log file: #{log_path}"
    end
  end

  ##
  # Single monitoring loop
  def monitoring_loop
    raise 'Tried to check supervisor script executior state, but it is not running' unless self.is_running
    unless check
      self.is_running = false
      if experiment.completed
        Rails.logger.info('Supervisor is terminated and experiment is completed')
      else
        Rails.logger.info('Supervisor is terminated, but experiment is not completed - reporting error')
        notify_error("Supervisor script is not running\nLast 100 lines of supervisor output:\n#{read_log}")
      end
    end
  end

  ##
  # Stops supervisor run execution
  def stop
    return unless self.pid && check
    Process.kill('TERM', self.pid)
    sleep 1
    Process.kill('KILL', self.pid) if check
    self.is_running = false
  end
  
  ##
  # Returns hash with supervisor_run_id and STATE_ALLOWED_KEYS
  def state
    res = {supervisor_run_id: self.id.to_s}
    res.merge! self.attributes.select {|x| STATE_ALLOWED_KEYS.include? x}
    res.symbolize_keys
  end

  ##
  # Overrides default destroy to make sure proper cleanup is run before destroying object.
  def destroy
    stop if check
    PROVIDER.get(self.supervisor_id).cleanup(self.experiment_id.to_s) unless self.supervisor_id.nil?
    super
  end
end
