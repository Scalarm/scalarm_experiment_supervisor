class SupervisorsController < ApplicationController
  include Scalarm::ServiceCore::CorsSupport

  before_filter :check_request_origin, only: [:start_panel]
  before_filter :cors_preflight_check, only: [:start_panel]
  before_filter :load_allowed_supervisors
  before_filter :load_manifest, only: [:show, :start_panel]
  after_filter :add_cors_header, only: [:start_panel]

=begin
  @api {get} /supervisors Supervisors description
  @apiName supervisor#index
  @apiGroup Supervisors
  @apiDescription Returns information about all Supervisors

  @apiParam {String} id ID of supervisor

  @apiSuccess {List} list List with object containing Supervisor description
  @apiSuccessExample {json} Success-Response
    [
      {
        'foo': bar
      },
      {
        'baz': 42
      }
    ]
=end
  def index
    allowed_manifests = Supervisor.get_manifests.select do |m|
      m[:public] or @allowed_supervisors.include? m[:id]
    end
    render json: allowed_manifests
  end

=begin
  @api {get} /supervisors/:id Supervisor description
  @apiName supervisor#show
  @apiGroup Supervisors
  @apiDescription Returns information about all Supervisors

  @apiParam {String} id ID of supervisor

  @apiSuccess {Object} info Object containing Supervisor description

  @apiSuccessExample {json} Success-Response

    {
          'foo': bar
    }

=end
  def show
    render json: @manifest
  end

=begin
  @api {get} /supervisors/:id/start_panel New SupervisorRun view
  @apiName supervisor#start_panel
  @apiGroup Supervisors
  @apiDescription Returns partial form to configure SupervisorRun

  @apiParam {String} id ID of Supervisor to show view
=end
  def start_panel
    path = Supervisor.view_path(params[:id]) || resource_not_found
    render path, layout: false
  end


  private
  def load_allowed_supervisors
    @allowed_supervisors = current_user.allowed_supervisors || []
  end

  private
  def load_manifest
    @manifest = Supervisor.get_manifest(params[:id])
    supervisor_allowed = (@allowed_supervisors.include? params[:id])
    unless @manifest.blank?
      supervisor_allowed ||= @manifest[:public]
    end
    resource_forbidden unless supervisor_allowed
    resource_not_found unless @manifest
  end

end
