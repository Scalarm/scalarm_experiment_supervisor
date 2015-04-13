require 'supervisor_script_executors/supervisor_script_executors'
Dir[Rails.root.join('supervisor_scripts', 'executors', '*_executor.rb').to_s].each {|file| require file}
##
# This class represents an instance of one supervisor script and maintains
# its creation, monitoring and deletion.
#
# List of possible attributes:
# * experiment_id - id of experiment that is supervised by script (set by #start method)
# * script_id - id of supervisor script, specify which script is used for supervising (set by #start
#   method)
# * pid - pid of supervisor script process (set by #start method)
class SupervisorScript < MongoActiveRecord

  ##
  # This method is needed for proper work of MongoActiveRecord,
  # its specifies collections name in database
  def self.collection_name
    'supervisor_scripts'
  end

  ##
  # Starts new supervised script. Performed actions:
  # * Gets Experiment Manager Address from Information Service
  # * Runs supervisor script using proper executor
  #
  # Required params
  # * id - id of supervisor script
  # * config - json with config for supervisor script (config is not validated)
  # Returns
  # * pid of started script
  # Raises
  # * Various StandardError exceptions caused by creating file or starting process.
  def start(id, config)
    raise 'There is no supervisor script with given id' unless SupervisorScriptExecutors.has_key? id
    self.script_id = id
    self.experiment_id = config['experiment_id']
    # TODO validate config
    information_service = InformationService.new
    config['address'] = information_service.get_list_of('experiment_managers').sample
    config['http_schema'] = 'https' # TODO - temporary, change to config entry
    self.pid = SupervisorScriptExecutors.get(id).start config
    Rails.logger.info "New supervisor script pid #{self.pid}"
    self.pid
  end

  ##
  # Overrides default destroy to make sure proper cleanup is run before destroying object.
  def destroy
    SupervisorScriptExecutors.get(self.script_id).cleanup(self.experiment_id) unless self.script_id.nil?
    super
  end
end
