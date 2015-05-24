require 'scalarm/service_core/scalarm_authentication'

require 'exceptions/resource_not_found'

class ApplicationController < ActionController::Base
  include Scalarm::ServiceCore::ScalarmAuthentication

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate, :except => [:status]

  rescue_from ResourceNotFound, with: :resource_not_found_handler

  def resource_not_found
    raise ResourceNotFound.new('Resource with given id not found')
  end

  private
  def resource_not_found_handler(exception)
    respond_to do |format|
      format.json do
        render json: {status: 404, reason: exception.to_s}, status: 404
      end
      format.html do
        flash[:error] = exception.to_s
        redirect_to action: :index
      end
    end
  end

end
