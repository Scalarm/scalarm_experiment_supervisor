##
# This class defines interface of supervisor script execution.
# Child classes must be declared in supervisor_scripts/executors directory
# Given executor must follow ruby class name convention (i.e. some_class.rb -> SomeClass)
# Class name of executor must be <script_id>Executor (filename <script_id>_executor.rb)
# Executor will be accessible under <script_id> id by SupervisorScriptExecutors.get method.
class AbstractSupervisorScriptExecutor
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
end