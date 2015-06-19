require 'test_helper'

class SupervisorRunsControllerTest < ActionController::TestCase

  ID = 'id'

  def setup
    stub_authentication
  end

  test 'new should redirect to supervisors#new_member' do
    get :new, supervisor_id: ID
    assert_redirected_to :controller=>'supervisors', :action => 'start_panel', :id => ID
  end

  test 'stop should execute stop on proper supervisor run' do
    run = mock do
      expects(:stop)
      expects(:save)
    end
    SupervisorRun.expects(:find_by_id).returns(run)

    post :stop, id: ID
    assert_equal 'ok', JSON.parse(response.body)['status']
  end

  test 'destroy should destroy proper supervisor run' do
    run = mock do
      expects(:destroy)
    end
    SupervisorRun.expects(:find_by_id).returns(run)

    delete :destroy, id: ID
    assert_equal 'ok', JSON.parse(response.body)['status']
  end

end
