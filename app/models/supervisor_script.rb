##
# This class represents an instance of one supervisor script and maintenance
# its creation, monitoring and deletion.
#
# List of possible attributes:
# * experiment_id - id of experiment that is supervised by script (sets by #start method)
# * script_id - id of supervisor script, specify which script is used for supervising (sets by #start
#   method)
# * pid - pid of supervisor script process (sets by #start method)
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
    self.pid
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
