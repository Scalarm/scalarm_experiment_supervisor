require 'supervisor_executors/abstract_supervisor_executor'
require_relative '../_virtroll_optimization_base/base_virtroll_optimization_executor'

# See docs for BaseVirtrollOptimizationExecutor
#
# ==== Supervisor specific parameters:
# hj_working_step_multiplier::
# hj_parallel::
class VirtrollOptimizationGeneticExecutor < AbstractSupervisorExecutor
  extend BaseVirtrollOptimizationExecutor
end