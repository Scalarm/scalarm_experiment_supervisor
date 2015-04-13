require_relative 'simulated_annealing_executor'
require_relative 'abstract_supervisor_script_executor'
##
# This class translates simulation scripts id to their executor
class SupervisorScriptExecutors
  ##
  # Translation from supervisor script id to executors
  SUPERVISOR_SCRIPT_EXECUTORS = {
      simulated_annealing: SimulatedAnnealingExecutor
  }

  ##
  # This method returns executor for given id
  def self.get(id)
    SUPERVISOR_SCRIPT_EXECUTORS[id.to_sym]
  end

  def self.has_key?(key)
    SUPERVISOR_SCRIPT_EXECUTORS.has_key?(key.to_sym)
  end
end