require 'scalarm/service_core/utils'

##
# This class defines interface of supervisor script execution.
# Child classes must be declared in supervisors/<supervisor_name> directory
# Given executor must follow ruby class name convention (i.e. some_class.rb -> SomeClass)
# Class name of executor must be <script_id>Executor (filename <script_id>_executor.rb)
# Executor will be accessible under <script_id> id by SupervisorScriptExecutorsProvider.get method.
class AbstractSupervisorExecutor
  NOT_IMPLEMENTED = 'This is an abstract method, which must be implemented by all subclasses'
  CONFIG_FILE_PREFIX = '/tmp/supervisor_script_config'

  ##
  # Raise error if experiment_id is not safe
  def self.validate_experiment_id!(experiment_id)
    unless experiment_id =~ Scalarm::ServiceCore::Utils::get_validation_regexp(:default)
      raise SecurityError.new('Insecure experiment id in supervisor configuration')
    end
  end

  ##
  # Raise error if configuration is not safe
  def self.validate_config_security!(config)
    validate_experiment_id!(config['experiment_id'])
  end

  ##
  # Template for invoking start method.
  def self._start(config)
    validate_config_security!(config)
    start(config)
  end

  ##
  # Template for invoking cleanup method
  def self._cleanup(experiment_id)
    validate_experiment_id!(experiment_id)
    cleanup(experiment_id)
  end

  ##
  # Method to start supervisor script with given config. Must be implemented in child classes.
  # config parameter will contain experiment_id entry which should be used in creating auxiliary files.
  # Return value must be pid of supervisor script
  def self.start(config)
    raise NOT_IMPLEMENTED
  end

  ##
  # Method to clean all created files after supervisor script execution. Must be implemented in child classes.
  def self.cleanup(experiment_id)
    raise NOT_IMPLEMENTED
  end

  ##
  # Default log path. Override if needed.
  def self.log_path(experiment_id)
    Rails.root.join('log', "supervisor_script_#{experiment_id}.log")
  end

  ##
  # Default path for config file.
  # Usage of config files are not mandatory - use for convenience.
  # This file will be removed on supervisor cleanup.
  def self.config_file_path(experiment_id)
    config_suffix = SecureRandom.hex(8)
    [CONFIG_FILE_PREFIX, experiment_id, config_suffix].join('_')
  end
end