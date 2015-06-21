require 'test_helper'

class SupervisorRunsControllerTest < ActionController::TestCase

  SUPERVISOR_ID = 'supervisor_id'
  EXPERIMENT_ID = 'experiment_id'
  STATE = '{state: :state}'

  def setup
    stub_authentication

    @supervisor_run = SupervisorRun.new({})
    @supervisor_run.stubs(:experiment_id).returns(EXPERIMENT_ID)
    @supervisor_run.stubs(:user_id).returns(@user.id)
    @supervisor_run.stubs(:save)
    SupervisorRun.stubs(:where).returns([@supervisor_run])
    SupervisorRun.stubs(:find_by_id).returns(@supervisor_run)

    @experiment = Scalarm::Database::Model::Experiment.new({})
    @experiment.stubs(:shared_with).returns([])
    @experiment.stubs(:user_id).returns(@user.id)
    Scalarm::Database::Model::Experiment.stubs(:where).returns([@experiment])
  end

  test 'index should return supervisor runs allowed to user' do
    @supervisor_run.expects(:state).returns(STATE)

    get :index
    assert_equal [STATE], JSON.parse(response.body)
  end

  test 'new should redirect to supervisors#start_panel' do
    get :new, supervisor_id: SUPERVISOR_ID
    assert_redirected_to :controller=>'supervisors', :action => 'start_panel', :id => SUPERVISOR_ID
  end

  test 'stop should execute stop on proper supervisor run when executed by owner' do
    @supervisor_run.expects(:stop)
    @supervisor_run.expects(:save)

    post :stop, id: SUPERVISOR_ID
    #assert_equal 'ok', JSON.parse(response.body)['status']
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'stop should return ok when executed by owner (json)' do
    post :stop, format: :json, id: SUPERVISOR_ID
    assert_equal 'ok', JSON.parse(response.body)['status']
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'stop should redirect to index when not executed by owner (html)' do
    @experiment.stubs(:user_id).returns('bad user id')

    post :stop, id: SUPERVISOR_ID
    assert_redirected_to action: :index
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'stop should return error when not executed by owner (json)' do
    @experiment.stubs(:user_id).returns('bad user id')

    post :stop, format: :json, id: SUPERVISOR_ID
    assert_equal 'error', JSON::parse(response.body)['status']
  end

  # since permissions checking happens in before filter, following test applies to other routes
  test 'stop should return 403 when not executed by owner (json)' do
    @experiment.stubs(:user_id).returns('bad user id')

    post :stop, format: :json, id: SUPERVISOR_ID
    assert_equal 403, response.status
  end

  test 'destroy should destroy proper supervisor run' do
    @supervisor_run.expects(:destroy)

    delete :destroy, id: SUPERVISOR_ID
    assert_equal 'ok', JSON.parse(response.body)['status']
  end

end
