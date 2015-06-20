require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  ID = 'test'
  BAD_ID = 'bad_id'
  PUBLIC_MANIFEST = {'id' => ID, 'test' => 'test', 'test2' => ['foo', 'bar', 42], 'public' => true}
  NON_PUBLIC_MANIFEST_EXPL = {'id' => 'non_public_expl', 'a' => 'a', 'bc3' => ['b', 'c', 3], 'public' => false}
  NON_PUBLIC_MANIFEST_IMPL = {'id' => 'non_public_impl', 'a' => 'a', 'bc3' => ['b', 'c', 3]}
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
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST], manifests
  end

  test 'show should return manifest of given supervisor id' do
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    get :show, id: ID
    manifest = JSON.parse(response.body)
    assert_equal PUBLIC_MANIFEST, manifest
  end

  test 'show should redirect to index on non existing id (html)' do
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, id: BAD_ID
    assert_redirected_to action: :index
  end

  test 'show should return 404 on non existing id (json)' do
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, format: :json, id: BAD_ID
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
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}

    request.headers['Origin'] = origin
    get :start_panel, {id: ID}
    assert_equal origin, response.headers['Access-Control-Allow-Origin']
  end

  test 'index should return only public manifests to user without permissions' do
    Supervisor.expects(:get_manifests).returns([PUBLIC_MANIFEST.symbolize_keys,
                                                NON_PUBLIC_MANIFEST_EXPL.symbolize_keys,
                                                NON_PUBLIC_MANIFEST_IMPL.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST], manifests
  end

  test 'index should return all allowed manifests to user with permissions' do
    @user.allowed_supervisors = %w(non_public_expl non_public_impl)
    Supervisor.expects(:get_manifests).returns([PUBLIC_MANIFEST.symbolize_keys,
                                                NON_PUBLIC_MANIFEST_EXPL.symbolize_keys,
                                                NON_PUBLIC_MANIFEST_IMPL.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST, NON_PUBLIC_MANIFEST_EXPL, NON_PUBLIC_MANIFEST_IMPL], manifests
  end

  # since permissions checking happens in before filter, following test applies to all non-index routes
  test 'show should return manifest to user with permissions' do
    @user.allowed_supervisors = %w(non_public_expl)
    Supervisor.expects(:get_manifest).with(NON_PUBLIC_MANIFEST_EXPL['id'])
        .returns(NON_PUBLIC_MANIFEST_EXPL.symbolize_keys)

    get :show, format: :json, id: NON_PUBLIC_MANIFEST_EXPL['id']
    manifest = JSON.parse(response.body)
    assert_equal NON_PUBLIC_MANIFEST_EXPL, manifest
  end

  # since permissions checking happens in before filter, following test applies to all non-index routes
  test 'show should return 403 to user without permissions' do
    Supervisor.expects(:get_manifest).with(NON_PUBLIC_MANIFEST_EXPL['id'])
        .returns(NON_PUBLIC_MANIFEST_EXPL.symbolize_keys)

    get :show, format: :json, id: NON_PUBLIC_MANIFEST_EXPL['id']
    assert_equal 403, response.status
  end

  # since permissions checking happens in before filter, following test applies to all non-index routes
  test 'show should redirect user without permissions to index(html)' do
    Supervisor.expects(:get_manifest).with(NON_PUBLIC_MANIFEST_EXPL['id'])
        .returns(NON_PUBLIC_MANIFEST_EXPL.symbolize_keys)

    get :show, id: NON_PUBLIC_MANIFEST_EXPL['id']
    assert_redirected_to action: :index
  end

end
