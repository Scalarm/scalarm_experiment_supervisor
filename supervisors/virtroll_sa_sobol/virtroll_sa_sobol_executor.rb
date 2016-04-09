require 'supervisor_executors/abstract_supervisor_executor'
require_relative '../_virtroll_sa_base/base_virtroll_sa_executor'

# See docs for BaseVirtrollSaExecutor
#
# ==== Supervisor specific parameters:
# sobol_base_inputs_count::
class VirtrollSaSobolExecutor < AbstractSupervisorExecutor
  extend BaseVirtrollSaExecutor
end