require 'scalarm/service_core/scalarm_authentication'
require 'scalarm/service_core/cors_support'

require 'exceptions/resource_not_found'
require 'exceptions/resource_forbidden'

class ApplicationController < ActionController::Base
  include Scalarm::ServiceCore::ScalarmAuthentication

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_filter :authenticate, :except => [:status]

  rescue_from ResourceNotFound, ResourceForbidden, with: :generic_exception_handler

  ##
  # Render trivial json if Accept: application/json specified,
  # for testing and authentication tests purposes
  def index
    respond_to do |format|
      format.json { render json: {status: 'ok',
                                  message: 'Welcome to Scalarm',
                                  user_id: @current_user.id.to_s } }
    end
  end

  def resource_not_found
    raise ResourceNotFound.new('Resource with given id not found')
  end

  def resource_forbidden
    raise ResourceForbidden.new('Resource with given id is unavailable for current user')
  end

  def authentication_failed
    Rails.logger.debug('[authentication] failed -> 401')
    @user_session.destroy unless @user_session.nil?
    headers['WWW-Authenticate'] = %(Basic realm="Scalarm")

    respond_to do |format|
      format.html do
        render html: 'Authentication failed', status: :unauthorized
      end

      format.json do
        render json: {status: 'error', reason: 'Authentication failed'}, status: :unauthorized
      end
    end
  end

  def generic_exception_handler(exception)
    respond_to do |format|
      format.json do
        render json: {status: exception.status, reason: exception.to_s}, status: exception.status
      end
      format.html do
        flash[:error] = exception.to_s
        redirect_to action: :index
      end
    end
  end

  protected :authentication_failed
  private :generic_exception_handler

end
