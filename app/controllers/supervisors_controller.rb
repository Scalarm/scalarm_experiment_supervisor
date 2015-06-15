class SupervisorsController < ApplicationController

  before_filter :check_request_origin, only: [:start_panel]
  before_filter :cors_preflight_check, only: [:start_panel]
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
    # TODO: each supervisor in manifest should have boolean field "public"
    # if it is true, all users can view and start it
    # else, ScalarmUser should have special permissions (eg. belong to group)
    render json: Supervisor.get_manifests
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
    # TODO: each supervisor in manifest should have boolean field "public"
    # if it is true, all users can view and start it
    # else, ScalarmUser should have special permissions (eg. belong to group)
    render json: Supervisor.get_manifest(params[:id]) || resource_not_found
  end

=begin
  @api {get} /supervisors/:id/start_panel New SupervisorRun view
  @apiName supervisor#start_panel
  @apiGroup Supervisors
  @apiDescription Returns partial form to configure SupervisorRun

  @apiParam {String} id ID of Supervisor to show view
=end
  def start_panel
    # TODO: each supervisor in manifest should have boolean field "public"
    # if it is true, all users can view and start it
    # else, ScalarmUser should have special permissions (eg. belong to group)
    render Supervisor.view_path(params[:id]) || resource_not_found, layout: false
  end

end
