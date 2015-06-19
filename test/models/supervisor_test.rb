require 'test_helper'

class SupervisorTest < ActiveSupport::TestCase
  ID = 'test'
  SUPERVISOR_DIRECTORY = Rails.root.join('supervisors', "#{ID}").to_s
  MANIFEST_TEST_FILE = Rails.root.join('supervisors', "#{ID}", 'manifest.yml')
  VIEW_TEST_FILE = Rails.root.join('supervisors', "#{ID}", 'start_panel.html')
  CONTENT = {foo: 'bar', number: 42}
  PARSED_CONTENT = CONTENT.merge({id: ID})

  def setup
    create_directory_if_not_exists SUPERVISOR_DIRECTORY
    File.open(MANIFEST_TEST_FILE, 'w+') {|f| f.write CONTENT.to_yaml }
    File.open(VIEW_TEST_FILE, 'w+') {|f| f.write ID }
    @count =  Dir[Rails.root.join('supervisors', '*', 'manifest.yml').to_s].count
  end

  def teardown
    remove_file_if_exists MANIFEST_TEST_FILE
    remove_file_if_exists VIEW_TEST_FILE
    remove_directory_if_exists SUPERVISOR_DIRECTORY
  end

  test 'get_manifests should return all yaml manifest' do
    manifest = Supervisor.get_manifests
    assert_equal manifest.length, @count
    assert manifest.include?(PARSED_CONTENT), 'Parsed manifest should contain test manifest'
  end

  test 'get_manifest should return test yaml manifest' do
    assert_equal Supervisor.get_manifest(ID), PARSED_CONTENT
  end

  test 'get_manifest should return nil on invalid id' do
    assert_nil Supervisor.get_manifest('bad id')
  end

  test 'view_path test with supervisor id' do
    assert_equal Supervisor.view_path(ID), VIEW_TEST_FILE.to_s
  end

  test 'view_path should return nil on non exist view file' do
    assert_nil Supervisor.view_path('bad id')
  end
end