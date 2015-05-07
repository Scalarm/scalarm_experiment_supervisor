require 'test_helper'

class SupervisorRunsControllerTest < ActionController::TestCase

  ID = 'id'

  test 'new should redirect to supervisors#new_member' do
    get :new, supervisor_id: ID
    assert_redirected_to :controller=>'supervisors', :action => 'start_panel', :id => ID
  end

end
