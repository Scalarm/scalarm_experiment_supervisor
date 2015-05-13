require 'test_helper'

class SupervisorTest < ActiveSupport::TestCase
  ID = 'test'
  MANIFEST_TEST_FILE = Rails.root.join('supervisors', 'manifest', "#{ID}.yml")
  VIEW_TEST_FILE = Rails.root.join('supervisors', 'views', "#{ID}.html")
  CONTENT = {foo: 'bar', number: 42}
  PARSED_CONTENT = CONTENT.merge({id: ID})

  def setup
    File.open(MANIFEST_TEST_FILE, 'w+') {|f| f.write CONTENT.to_yaml }
    File.open(VIEW_TEST_FILE, 'w+') {|f| f.write ID }
    @count =  Dir[Rails.root.join('supervisors', 'manifest', '*.yml').to_s].count
  end

  def teardown
    remove_file_if_exists MANIFEST_TEST_FILE
    remove_file_if_exists VIEW_TEST_FILE
  end

  test 'get_maniphests should return all yaml manifest' do
    maniphests = Supervisor.get_maniphests
    assert_equal maniphests.length, @count
    assert maniphests.include?(PARSED_CONTENT), 'Parsed maniphests should contain test manifest'
  end

  test 'get_maniphest should return test yaml manifest' do
    assert_equal Supervisor.get_maniphest(ID), PARSED_CONTENT
  end

  test 'get_maniphest should return nil on invalid id' do
    assert_nil Supervisor.get_maniphest('bad id')
  end

  test 'view_path test with supervisor id' do
    assert_equal Supervisor.view_path(ID), VIEW_TEST_FILE.to_s
  end

  test 'view_path should return nil on non exist view file' do
    assert_nil Supervisor.view_path('bad id')
  end
end