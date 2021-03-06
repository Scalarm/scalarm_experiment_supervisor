require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  ID = 'test'
  UNSAFE_ID = '<script>alert(1)</script>'
  BAD_ID = 'bad_id'
  PUBLIC_MANIFEST = {'id' => ID, 'test' => 'test', 'test2' => ['foo', 'bar', 42], 'public' => true}
  EXPL_NON_PUBLIC_MANIFEST = {'id' => 'expl_non_public', 'a' => 'a', 'bc3' => ['b', 'c', 3], 'public' => false}
  IMPL_NON_PUBLIC_MANIFEST = {'id' => 'impl_non_public', 'a' => 'a', 'bc3' => ['b', 'c', 3]}
  PUBLIC_RESTRICTED_LIST_MANIFEST = {'id' => 'public_restricted_list_1', 'restricted_list' => true, 'public' => true}
  PRIVATE_RESTRICTED_LIST_MANIFEST = {'id' => 'private_restricted_list_1', 'restricted_list' => true, 'public' => false}
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

  test 'show should not allow to use unsafe supervisor id' do
    Supervisor.stubs(:get_manifest).with(UNSAFE_ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    get :show, id: UNSAFE_ID, format: :json
    assert_response :precondition_failed
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
    assert_response :not_found
  end

  test 'start_panel should return proper view' do
    Supervisor.expects(:get_manifest).with(ID).returns(PUBLIC_MANIFEST.symbolize_keys)
    File.open(VIEW_TEST_FILE, 'w+') {|file| file.write ID}
    get :start_panel, id: ID
    assert_equal ID, response.body
  end

  test 'start_panel should not allow to use unsafe supervisor id' do
    Supervisor.stubs(:get_manifest).with(UNSAFE_ID).returns(PUBLIC_MANIFEST.symbolize_keys)

    get :show, id: UNSAFE_ID

    assert_redirected_to action: :index
    assert_not_empty flash[:error]
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
    assert_response :not_found
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

  test 'index should not return public restricted_list manifests to user without permissions' do
    @user.allowed_supervisors = []
    Supervisor.stubs(:get_manifests).returns([PUBLIC_RESTRICTED_LIST_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [], manifests
  end

  test 'index should return public restricted_list manifests to user with permissions' do
    @user.allowed_supervisors = [PUBLIC_RESTRICTED_LIST_MANIFEST['id']]
    Supervisor.stubs(:get_manifests).returns([PUBLIC_RESTRICTED_LIST_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [PUBLIC_RESTRICTED_LIST_MANIFEST], manifests
  end

  test 'index should not return private restricted_list manifests to user without permissions' do
    @user.allowed_supervisors = []
    Supervisor.stubs(:get_manifests).returns([PRIVATE_RESTRICTED_LIST_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [], manifests
  end

  test 'index should not return private non-restricted_list manifests to user without permissions' do
    @user.allowed_supervisors = []
    Supervisor.stubs(:get_manifests).returns([EXPL_NON_PUBLIC_MANIFEST.symbolize_keys])

    get :index
    manifests = JSON.parse(response.body)
    assert_equal [], manifests
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
    assert_response :forbidden
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
    assert_response :forbidden
  end

end
