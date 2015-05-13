require 'supervisor_executors/supervisor_executors_provider'
Dir[Rails.root.join('supervisors', 'executors', '*_executor.rb').to_s].each {|file| require file}
##
# This class represents an instance of one supervisor script and maintains
# its creation, monitoring and deletion.
#
# List of possible attributes:
# * experiment_id - id of experiment that is supervised by script (set by #start method)
# * supervisor_id - id of supervisor, specify which script is used for supervising (set by #start
#   method)
# * pid - pid of supervisor script process (set by #start method)
# * is_running - true when supervisor script is running, false otherwise (set by #start, modified by #check)
# * experiment_manager_credentials - hash with credentials to experiment manager (set by #start):
#   * user
#   * password
class SupervisorRun < MongoActiveRecord

  PROVIDER = SupervisorExecutorsProvider

  ##
  # This method is needed for proper work of MongoActiveRecord,
  # its specifies collections name in database
  def self.collection_name
    'supervisors'
  end

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
  def start(id, config)
    raise 'There is no supervisor script with given id' unless PROVIDER.has_key? id
    self.supervisor_id = id
    self.experiment_id = config['experiment_id']
    self.experiment_manager_credentials = {user: config['user'], password: config['password']}
    # TODO validate config
    information_service = InformationService.new
    config['address'] = information_service.get_list_of('experiment_managers').sample
    config['http_schema'] = 'https' # TODO - temporary, change to config entry
    self.pid = PROVIDER.get(id).start config
    Rails.logger.info "New supervisor script pid #{self.pid}"
    self.is_running = true
    SupervisorRunWatcher.start_watching
    self.pid
  end

  ##
  # Returns log_path for given supervisor script
  def log_path
    PROVIDER.get(self.supervisor_id).log_path(self.experiment_id)
  end

  ##
  # This functions checks if supervisor script is running
  # Set is_running flag to false when script is not running
  def check
    `ps #{self.pid}`
    unless $?.success?
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
  # Returns last 100 lines of script log
  def read_log()
    IO.readlines(log_path)[-100..-1].join
  end

  ##
  # Single monitoring loop
  def monitoring_loop
    raise 'Supervisor script is not running' unless self.is_running
    notify_error("Supervisor script is not running\nLast 100 lines of supervisor output:\n#{read_log}") unless check
  end


  ##
  # Overrides default destroy to make sure proper cleanup is run before destroying object.
  def destroy
    PROVIDER.get(self.supervisor_id).cleanup(self.experiment_id) unless self.supervisor_id.nil?
    super
  end
end
