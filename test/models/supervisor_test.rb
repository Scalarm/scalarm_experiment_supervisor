require 'test_helper'

class SupervisorTest < ActiveSupport::TestCase
  ID = 'test'
  TEST_FILE = File.join(Rails.root.join('supervisors', 'maniphest', "#{ID}.yml"))
  CONTENT = {foo: 'bar', number: 42}
  PARSED_CONTENT = CONTENT.merge({id: ID})

  def setup
    File.open(TEST_FILE, 'w+') {|f| f.write CONTENT.to_yaml }
    @count =  Dir[Rails.root.join('supervisors', 'maniphest', '*.yml').to_s].count
  end

  def teardown
    File.delete TEST_FILE if File.exists? TEST_FILE
  end

  test 'getManiphests should return all yaml maniphest' do
    maniphests = Supervisor.get_maniphests
    assert_equal maniphests.length, @count
    assert maniphests.include?(PARSED_CONTENT), 'Parsed maniphests should contain test maniphest'
  end

  test 'getManiphest should return test yaml maniphest' do
    assert_equal Supervisor.get_maniphest(ID), PARSED_CONTENT
  end

  test 'getManiphest should return nil on invalid id' do
    assert_nil Supervisor.get_maniphest('bad id')
  end
end