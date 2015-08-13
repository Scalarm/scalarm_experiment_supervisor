require 'scalarm/service_core/scalarm_authentication'
require 'scalarm/service_core/cors_support'

require 'exceptions/resource_not_found'
require 'exceptions/resource_forbidden'
require 'exceptions/precondition_failed'

require 'erb'

class ApplicationController < ActionController::Base
  include Scalarm::ServiceCore::ScalarmAuthentication
  include Scalarm::ServiceCore::ParameterValidation
  include ERB::Util

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_filter :authenticate, :except => [:status]


  rescue_from SecurityError, with: :handle_security_error
  rescue_from ResourceNotFound, ResourceForbidden,
              PreconditionFailed, with: :generic_exception_handler

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

  def precondition_failed
    raise PreconditionFailed.new('Invalid parameter specified')
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

  ##
  # Use generic exception handler to handle
  # PreconditionFailed based on security error with proper message
  def handle_security_error(exception)
    Rails.logger.warn("Security exception caught: #{exception.to_s}")
    generic_exception_handler(PreconditionFailed.new(exception.to_s))
  end

  def generic_exception_handler(exception)
    Rails.logger.warn("Controller exception caught: #{exception.to_s}")
    respond_to do |format|
      format.json do
        render json: {status: 'error', reason: exception.to_s}, status: exception.status
      end
      format.html do
        flash[:error] = exception.to_s
        redirect_to action: :index
      end
    end
  end

  protected :authentication_failed
  private :handle_security_error, :generic_exception_handler

end
