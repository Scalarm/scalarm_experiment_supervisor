require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  MANIFEST = {'test' => 'test', 'test2' => ['foo', 'bar', 42]}
  ID = 'test'
  SUPERVISOR_DIRECTORY = Rails.root.join('supervisors', "#{ID}").to_s
  VIEW_TEST_FILE = Rails.root.join('supervisors', "#{ID}", 'start_panel.html')

  def setup
    create_directory_if_not_exists SUPERVISOR_DIRECTORY
    stub_authentication
  end

  def teardown
    remove_file_if_exists VIEW_TEST_FILE
    remove_directory_if_exists SUPERVISOR_DIRECTORY
  end

  test 'index should return manifest of supervisors' do
    Supervisor.expects(:get_manifests).returns([MANIFEST])
    get :index
    manifest = JSON.parse(response.body)
    assert_equal manifest, [MANIFEST]
  end

  test 'show should return manifest of given supervisor id' do
    Supervisor.expects(:get_manifest).with(ID).returns(MANIFEST)
    get :show, id: ID
    manifest = JSON.parse(response.body)
    assert_equal manifest, MANIFEST
  end

  test 'show should redirect to index on non existing id (html)' do
    get :show, id: 'bad id'
    assert_redirected_to action: :index
  end

  test 'show should return 404 on non existing id (json)' do
    get :show, format: :json, id: 'bad id'
    assert_equal response.status, 404
  end

  test 'new_member should return proper view' do
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}
    get :start_panel, id: ID
    assert_equal response.body, ID
  end

  test 'new_member should redirect to index on non existing id (html)' do
    get :start_panel, id: ID
    assert_redirected_to action: :index
  end

  test 'new_member should return 404 on non existing id (json)' do
    get :start_panel, format: :json, id: ID
    assert_equal response.status, 404
  end

  test 'start_panel should support CORS on valid request' do
    origin = 'test_localhost'
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}

    request.headers['Origin'] = origin
    get :start_panel, {id: ID}
    assert_equal origin, response.headers['Access-Control-Allow-Origin']
  end

end
