require 'supervisor_executors/abstract_supervisor_executor'
require_relative '../_virtroll_optimization_base/base_virtroll_optimization_executor'

# See docs for BaseVirtrollOptimizationExecutor
#
# ==== Supervisor specific parameters:
# genetic_population_start::
# genetic_population_max::
class VirtrollOptimizationPsoExecutor < AbstractSupervisorExecutor
  extend BaseVirtrollOptimizationExecutor
end