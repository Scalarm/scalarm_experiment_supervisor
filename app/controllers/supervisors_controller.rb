class SupervisorsController < ApplicationController

  before_filter :add_cors_header, only: [:start_panel]

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
    allowed_supervisors = @current_user.allowed_supervisors || []
    allowed_manifests = Supervisor.get_manifests.select do |m|
      m[:public] or ((not allowed_supervisors.blank?) and allowed_supervisors.include? m[:id])
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
    allowed_supervisors = @current_user.allowed_supervisors || []
    manifest = Supervisor.get_manifest(params[:id]) || resource_not_found
    allowed = (
        ((not manifest.blank?) and manifest[:public])  or
        ((not allowed_supervisors.blank?) and allowed_supervisors.include? manifest[:id])
    )
    render json: allowed ? manifest : resource_forbidden
  end

=begin
  @api {get} /supervisors/:id/start_panel New SupervisorRun view
  @apiName supervisor#start_panel
  @apiGroup Supervisors
  @apiDescription Returns partial form to configure SupervisorRun

  @apiParam {String} id ID of Supervisor to show view
=end
  def start_panel
    allowed_supervisors = @current_user.allowed_supervisors || []
    manifest = Supervisor.get_manifest(params[:id])
    path = Supervisor.view_path(params[:id]) || resource_not_found
    allowed = (
        ((not manifest.blank?) and manifest[:public]) or
        ((not allowed_supervisors.blank?) and allowed_supervisors.include? manifest[:id])
    )
    render allowed ? path : resource_forbidden, layout: false
  end

end
