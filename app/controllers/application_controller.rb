require 'scalarm/service_core/scalarm_authentication'

require 'exceptions/resource_not_found'
require 'exceptions/resource_forbidden'

class ApplicationController < ActionController::Base
  include Scalarm::ServiceCore::ScalarmAuthentication

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_filter :cors_preflight_check
  before_filter :authenticate, :except => [:status]

  rescue_from ResourceNotFound, with: :resource_not_found_handler
  rescue_from ResourceForbidden, with: :resource_forbidden_handler

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

  def resource_forbidden_handler(exception)
    respond_to do |format|
      format.json do
        render json: {status: 403, reason: exception.to_s}, status: 403
      end
      format.html do
        flash[:error] = exception.to_s
        redirect_to action: :index
      end
    end
  end

  def add_cors_header
    # TODO: list of allowed origins from config
    headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = '1728000'
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      # TODO: list of allowed origins from config
      headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
      headers['Access-Control-Allow-Credentials'] = 'true'
      headers['Access-Control-Allow-Methods'] = 'OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'

      render :text => '', :content_type => 'text/plain'
    end
  end

  protected :authentication_failed, :add_cors_header, :cors_preflight_check
  private :resource_not_found_handler

end
