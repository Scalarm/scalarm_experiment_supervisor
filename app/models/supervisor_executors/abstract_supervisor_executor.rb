##
# This class defines interface of supervisor script execution.
# Child classes must be declared in supervisors/<supervisor_name> directory
# Given executor must follow ruby class name convention (i.e. some_class.rb -> SomeClass)
# Class name of executor must be <script_id>Executor (filename <script_id>_executor.rb)
# Executor will be accessible under <script_id> id by SupervisorScriptExecutorsProvider.get method.
class AbstractSupervisorExecutor
  NOT_IMPLEMENTED = 'This is an abstract method, which must be implemented by all subclasses'

  ##
  # Method to start supervisor script with given config. Must be implemented in child classes.
  # config parameter will contain experiment_id entry which should be used in creating auxiliary files.
  # Return value must be pid of supervisor script
  def self.start(config)
    raise NOT_IMPLEMENTED
  end

  ##
  # Method to clean all created files after supervisor script execution. Must be implemented in child classes.
  def self.cleanup(exeperiment_id)
    raise NOT_IMPLEMENTED
  end

  ##
  # Default log path. Override if needed.
  def self.log_path(experiment_id)
    Rails.root.join('log', "supervisor_script_#{experiment_id}.log")
  end
end