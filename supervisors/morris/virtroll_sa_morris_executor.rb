require 'supervisor_executors/abstract_supervisor_executor'
require_relative '../_virtroll_sa_base/base_virtroll_sa_executor'

# See docs for BaseVirtrollSaExecutor
#
# ==== Supervisor specific parameters:
# morris_samples_count::
# morris_levels_count::
class MorrisExecutor < AbstractSupervisorExecutor
  extend BaseVirtrollSaExecutor
end