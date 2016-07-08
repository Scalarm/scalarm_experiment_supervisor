ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/mini_test'
require 'scalarm/service_core/test_utils/test_helper_extensions'

class ActiveSupport::TestCase
  include Scalarm::ServiceCore::TestUtils::TestHelperExtensions

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  def remove_file_if_exists(file)
    File.delete file if File.exists? file
  end

  def create_directory_if_not_exists(dir)
    Dir.mkdir dir unless Dir.exist? dir
  end

  def remove_directory_if_exists(dir)
    Dir.rmdir dir if Dir.exist? dir
  end
end
