require 'test_helper'
require 'json'

class StatusControllerTest < ActionController::TestCase
  ## workaround for MiniTest errors on some configurations
  tests StatusController

  test 'status should be accessed without authentication' do
    get :status
    assert_response :success
  end

end
