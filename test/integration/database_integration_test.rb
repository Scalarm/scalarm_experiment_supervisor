require 'test_helper'
require 'scalarm/service_core/test_utils/db_helper'

class SimulatedAnnealingStartingTest < ActionDispatch::IntegrationTest
  include Scalarm::ServiceCore::TestUtils::DbHelper

  test 'supervisor_run should return experiment with joined attribute' do
    require 'scalarm/database/model/experiment'

    experiment = Scalarm::Database::Model::Experiment.new(foo: 'bar')
    experiment.save

    supervisor_run = SupervisorRun.new({})

    supervisor_run.experiment_id = experiment.id
    supervisor_run.save

    joined_experiment = supervisor_run.experiment

    assert_equal joined_experiment.id, experiment.id
    assert_equal joined_experiment.foo, experiment.foo
  end

end