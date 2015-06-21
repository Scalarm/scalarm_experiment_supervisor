require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  ID = 'test'
  BAD_ID = 'bad_id'
  PUBLIC_MANIFEST = {'id' => ID, 'test' => 'test', 'test2' => ['foo', 'bar', 42], 'public' => true}
  EXPL_NON_PUBLIC_MANIFEST = {'id' => 'expl_non_public', 'a' => 'a', 'bc3' => ['b', 'c', 3], 'public' => false}
  IMPL_NON_PUBLIC_MANIFEST = {'id' => 'impl_non_public', 'a' => 'a', 'bc3' => ['b', 'c', 3]}
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

  test 'show should redirect to index on not existing id (html)' do
    @user.allowed_supervisors = [BAD_ID]
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, id: BAD_ID
    assert_redirected_to action: :index
  end

  test 'show should return 404 on not existing id (json)' do
    @user.allowed_supervisors = [BAD_ID]
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, format: :json, id: BAD_ID
    assert_equal 404, response.status
  end

  test 'start_panel should return proper view' do
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}
    get :start_panel, id: ID
    assert_equal ID, response.body
  end

  test 'start_panel should redirect to index on not existing id (html)' do
    @user.allowed_supervisors = [BAD_ID]
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :start_panel, id: BAD_ID
    assert_redirected_to action: :index
  end

  test 'start_panel should return 404 on not existing id (json)' do
    @user.allowed_supervisors = [BAD_ID]
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :start_panel, format: :json, id: BAD_ID
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
                                                EXPL_NON_PUBLIC_MANIFEST.symbolize_keys,
                                                IMPL_NON_PUBLIC_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST], manifests
  end

  test 'index should return all allowed manifests to user with permissions' do
    @user.allowed_supervisors = [EXPL_NON_PUBLIC_MANIFEST['id'],
                                 IMPL_NON_PUBLIC_MANIFEST['id']]
    Supervisor.expects(:get_manifests).returns([PUBLIC_MANIFEST.symbolize_keys,
                                                EXPL_NON_PUBLIC_MANIFEST.symbolize_keys,
                                                IMPL_NON_PUBLIC_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_MANIFEST, EXPL_NON_PUBLIC_MANIFEST, IMPL_NON_PUBLIC_MANIFEST], manifests
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'show should return manifest to user with permissions' do
    @user.allowed_supervisors = [EXPL_NON_PUBLIC_MANIFEST['id']]
    Supervisor.expects(:get_manifest).with(EXPL_NON_PUBLIC_MANIFEST['id'])
        .returns(EXPL_NON_PUBLIC_MANIFEST.symbolize_keys)

    get :show, format: :json, id: EXPL_NON_PUBLIC_MANIFEST['id']
    manifest = JSON.parse(response.body)
    assert_equal EXPL_NON_PUBLIC_MANIFEST, manifest
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'show should redirect user without permissions to index (html)' do
    Supervisor.expects(:get_manifest).with(EXPL_NON_PUBLIC_MANIFEST['id'])
        .returns(EXPL_NON_PUBLIC_MANIFEST.symbolize_keys)

    get :show, id: EXPL_NON_PUBLIC_MANIFEST['id']
    assert_redirected_to action: :index
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'show should return 403 to user without permissions (json)' do
    Supervisor.expects(:get_manifest).with(EXPL_NON_PUBLIC_MANIFEST['id'])
        .returns(EXPL_NON_PUBLIC_MANIFEST.symbolize_keys)

    get :show, format: :json, id: EXPL_NON_PUBLIC_MANIFEST['id']
    assert_equal 403, response.status
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'show should redirect user without permissions to index on not existing id(html)' do
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, id: BAD_ID
    assert_redirected_to action: :index
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'show should return 403 to user without permissions on not existing id (json)' do
    Supervisor.expects(:get_manifest).with(BAD_ID).returns(nil)

    get :show, format: :json, id: BAD_ID
    assert_equal 403, response.status
  end

end
