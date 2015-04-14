require 'json'
##
# This class represents an instance of one supervisor script and maintenance
# its creation, monitoring and deletion.
#
# List of possible attributes:
# * experiment_id - id of experiment that is supervised by script (set by #start method)
# * script_id - id of supervisor script, specify which script is used for supervising (set by #start
#   method)
# * pid - pid of supervisor script process (set by #start method)
# * is_running - true when supervisor script is running, false otherwise (set by #start, modified by #check)
# * experiment_manager_credentials - hash with credentials to experiment manager (set by #start):
#   * user
#   * password
class SupervisorScript < MongoActiveRecord

  ##
  # This method is needed for proper work of MongoActiveRecord,
  # its specifies collections name in database
  def self.collection_name
    'supervisor_scripts'
  end

  SM_PATH = 'scalarm_supervisor_scrpits/simulated_annealing/anneal.py'
  LOG_FILE_PREFIX = 'log/supervisor_script_log_'
  LOG_FILE_SUFFIX = '.log'
  CONFIG_FILE_PREFIX = '/tmp/supervisor_script_config_'

  ##
  # Starts new supervised script (for now only simulated annealing one). Performed actions:
  # * Gets Experiment Manager Address from Information Service
  # * Creates config file in /tmp/supervisor_script_config_<experiment_id>
  # * Starts supervisor script with output set to log/supervisor_script_log_<experiment_id>
  # * Starts supervisor script watcher
  #
  # Required params
  # * id - id of supervisor script (for now only placeholder)
  # * config - json with config for supervisor script (config is not validated)
  # Returns
  # * pid of startes script
  # Raises
  # * Various StandardError exceptions caused by creating file or process starting.
  def start(id, config)
    self.experiment_id = config['experiment_id']
    self.script_id = id
    self.experiment_manager_credentials = {user: config['user'], password: config['password']}
    # TODO validate config
    # TODO use of id
    information_service = InformationService.new

    config['address'] = information_service.get_list_of('experiment_managers').sample
    config['http_schema'] = 'https' # TODO - temporary, change to config entry

    script_config = "#{CONFIG_FILE_PREFIX}#{self.experiment_id.to_s}"
    File.open(script_config, 'w+') { |file| file.write(config.to_json) }

    script_log = "#{LOG_FILE_PREFIX}#{self.experiment_id.to_s}#{LOG_FILE_SUFFIX}"

    self.pid = Process.spawn("python2 #{SM_PATH} #{script_config}", out: script_log, err: script_log)
    Process.detach(self.pid)
    Rails.logger.info "New supervisor script pid #{self.pid}"
    self.is_running = true
    SupervisorScriptWatcher.start_watching
    self.pid
  end

  ##
  # This functions checks if supervisor script is running
  # Set is_running flag to false when script is not running
  def check
    result = `ps #{self.pid} | wc -l`.to_i
    if result == 1
      self.is_running = false
      Rails.logger.info "Supervisor script is not running anymore: #{self.id}"
      return false
    end
    true
  end

  ##
  # This method notifies error with supervisor script to experiment manager.
  # Execution of this action will put experiment to error state
  def notify_error(reason)
    begin
      information_service = InformationService.new
      address = information_service.get_list_of('experiment_managers').sample
      raise 'There is no available experiment manager instance' if address.nil?
      schema = 'https' # TODO - temporary, change to config entry

      Rails.logger.debug "Connecting to experiment manager on #{address}"
      res = RestClient::Request.execute(
          method: :post,
          url: "#{schema}://#{address}/experiments/#{self.experiment_id}/mark_as_complete.json",
          payload: {status: 'error', reason: reason},
          user: self.experiment_manager_credentials['user'],
          password: self.experiment_manager_credentials['password'],
          verify_ssl: false
      )
      Rails.logger.debug "Experiment manager response #{res}"
      raise 'Error while sending error message' if JSON.parse(res)['status'] != 'ok'
    rescue RestClient::Exception, StandardError => e
      Rails.logger.info "Unable to connect with experiment manager, please contact administrator: #{e.to_s}"
    end
  end

  ##
  # Single monitoring loop
  def monitoring_loop
    raise 'Supervisor script is not running' unless self.is_running
    notify_error('Supervisor script is not running') unless check
  end


  ##
  # Overrides default destroy to make sure proper cleanup is run before destroying object.
  def destroy
    cleanup
    super
  end

  private

    ##
    # Private method.
    # Removes config and log files of supervisor script
    def cleanup
      if File.exists? "#{LOG_FILE_PREFIX}#{self.experiment_id.to_s}#{LOG_FILE_SUFFIX}"
        File.delete "#{LOG_FILE_PREFIX}#{self.experiment_id.to_s}#{LOG_FILE_SUFFIX}"
      end
      File.delete "#{CONFIG_FILE_PREFIX}#{self.experiment_id.to_s}" if File.exists? "#{CONFIG_FILE_PREFIX}#{self.experiment_id.to_s}"
    end

end
