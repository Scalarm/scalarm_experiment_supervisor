ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  # Drop all collections after each test case.
  def teardown
    db = MongoActiveRecord.get_database('scalarm_db_test')
    db.collections.each do |collection|
      collection.remove unless collection.name.start_with? 'system.'
    end
  end

  # Make sure that each test case has a teardown
  # method to clear the db after each test.
  def inherited(base)
    base.define_method :teardown do
      super
    end
  end

  EXPERIMENT_ID = 'some_id'

  def simulated_annealing_id
    'simulated_annealing'
  end

  def simulated_annealing_correct_params
    params = {
        maxiter: 1,
        dwell: 1,
        schedule: 'boltzmann',
        experiment_id: EXPERIMENT_ID,
        user: 'user',
        password: 'password',
        address: 'none',
        lower_limit: [],
        upper_limit: [],
        parameters_ids: [],
        start_point: []
    }
    params.to_json
  end

  def script_log_file_path
    "log/supervisor_script_log_#{EXPERIMENT_ID}"
  end

  def script_config_file_path
    "/tmp/supervisor_script_config_#{EXPERIMENT_ID}"
  end
end
