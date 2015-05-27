require 'test_helper'
require 'json'

class StatusControllerTest < ActionController::TestCase

  test 'status should be accessed without authentication' do
    get :status
    assert_response :success
  end

end
