Dir[Rails.root.join('supervisors', '*', '*_executor.rb').to_s].each {|file| require file}
require_relative 'abstract_supervisor_executor'
##
# This class translates simulation scripts id to their executor
class SupervisorExecutorsProvider

  ##
  # Translation from supervisor script id to executors
  SUPERVISOR_SCRIPT_EXECUTORS = {}

  ##
  # All executors are autoloaded from supervisors/executors directory
  # Mapping is <script_id> -> <script_id>Executor (symbol to class)
  def self.init
    Dir[Rails.root.join('supervisors', '*', '*_executor.rb').to_s].each do|file|
      name = File.basename(file, File.extname(file))
      SUPERVISOR_SCRIPT_EXECUTORS[name.rpartition('_executor').first.to_sym] = Object.const_get name.camelize
    end
  end

  ##
  # This method returns executor for given id
  def self.get(id)
    SUPERVISOR_SCRIPT_EXECUTORS[id.to_sym]
  end

  def self.has_key?(key)
    SUPERVISOR_SCRIPT_EXECUTORS.has_key?(key.to_sym)
  end


end