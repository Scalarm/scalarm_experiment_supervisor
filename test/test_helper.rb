ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  def remove_file_if_exists(file)
    File.delete file if File.exists? file
  end

  ##
  # A @user variable will contain session's ScalarmUser
  def stub_authentication
    # bypass authentication
    ApplicationController.any_instance.stubs(:authenticate)
    @user = Scalarm::ServiceCore::ScalarmUser.new(login: 'login')
    ApplicationController.stubs(:instance_variable_get).with(:@current_user).returns(@user)
  end
end
