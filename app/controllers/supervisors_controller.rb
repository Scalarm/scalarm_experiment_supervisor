class SupervisorsController < ApplicationController

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
    render Supervisor.view_path(params[:id]) || resource_not_found, layout: false
  end
end
