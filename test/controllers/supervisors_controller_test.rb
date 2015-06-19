require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  PUBLIC_MANIFEST = {'test' => 'test', 'test2' => ['foo', 'bar', 42], 'public' => true}
  NON_PUBLIC_MANIFEST_EXPL = {'a' => 'a', 'bc3' => ['b', 'c', 3], 'public' => false}
  RESTRICTED_MANIFEST_IMPL = {'a' => 'a', 'bc3' => ['b', 'c', 3]}
  ID = 'test'
  VIEW_TEST_FILE = Rails.root.join('supervisors', 'views', "#{ID}.html")

  def setup
    stub_authentication
  end

  def teardown
    remove_file_if_exists VIEW_TEST_FILE
  end

  test 'index should return manifest of supervisors' do
    Supervisor.expects(:get_manifests).returns([PUBLIC_MANIFEST.symbolize_keys])
    get :index
    manifest = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST], manifest
  end

  test 'show should return manifest of given supervisor id' do
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    get :show, id: ID
    manifest = JSON.parse(response.body)
    assert_equal PUBLIC_MANIFEST, manifest
  end

  test 'show should redirect to index on non existing id (html)' do
    get :show, id: 'bad id'
    assert_redirected_to action: :index
  end

  test 'show should return 404 on non existing id (json)' do
    get :show, format: :json, id: 'bad id'
    assert_equal 404, response.status
  end

  test 'new_member should return proper view' do
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}
    get :start_panel, id: ID
    assert_equal ID, response.body
  end

  test 'new_member should redirect to index on non existing id (html)' do
    get :start_panel, id: ID
    assert_redirected_to action: :index
  end

  test 'new_member should return 404 on non existing id (json)' do
    get :start_panel, format: :json, id: ID
    assert_equal 404, response.status
  end

  test 'start_panel should support CORS on valid request' do
    origin = 'test_localhost'
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}

    request.headers['Origin'] = origin
    get :start_panel, {id: ID}
    assert_equal origin, response.headers['Access-Control-Allow-Origin']
  end

end
