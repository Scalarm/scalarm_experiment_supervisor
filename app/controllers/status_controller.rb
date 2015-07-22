require 'scalarm/service_core/utils'
require 'scalarm/service_core/status_controller'

class StatusController < ApplicationController
  include Scalarm::ServiceCore::StatusController

  def status
    super
  end
end
