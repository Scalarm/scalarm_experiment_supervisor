require 'test_helper'
require 'json'

class SupervisorsControllerTest < ActionController::TestCase

  MANIPHEST = {'test' => 'test', 'test2' => ['foo', 'bar', 42]}
  ID = 'test'

  test 'index should return maniphests of supervisors' do
    Supervisor.expects(:get_maniphests).returns([MANIPHEST])
    get :index
    maniphests = JSON.parse(response.body)
    assert_equal maniphests, [MANIPHEST]
  end

  test 'show should return maniphests of given supervisor id' do
    Supervisor.expects(:get_maniphest).with(ID).returns(MANIPHEST)
    get :show, id: ID
    maniphests = JSON.parse(response.body)
    assert_equal maniphests, MANIPHEST
  end

  test 'show should return 404 on non existing id' do
    assert_raises ActionController::RoutingError do
      get :show, id: 'bad id'
    end
  end

end
