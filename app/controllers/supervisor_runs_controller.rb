require 'json'
require 'scalarm/service_core/utils'

class SupervisorRunsController < ApplicationController
  before_filter :load_supervisor_run, only: [:show, :stop, :destroy]
  before_filter :check_supervisor_owners, only: [:stop, :destroy]

  def index
    user_experiments_ids = Scalarm::Database::Model::Experiment.where(
        {'$or' => [{'user_id' => current_user.id}, {'shared_with' => current_user.id}]},
        fields: ['_id']).map { |e| e.id}
    or_query = []
    user_experiments_ids.each do |eid|
      or_query << {'experiment_id' => eid}
    end
    result = if or_query.blank?
               []
             else
               SupervisorRun.where('$or' => or_query).map { |sr| sr.state}
             end

    render json: result
  end

=begin
  @api {get} /supervisor_runs New SupervisorRun view
  @apiName supervisor_runs#new
  @apiGroup SupervisorRuns
  @apiDescription Returns partial form to configure SupervisorRun by redirection to /supervisors/:supervisor_id/start_panel

  @apiParam {String} supervisor_id ID of Supervisor to show view

=end
  def new
    redirect_to :controller=>'supervisors', :action => 'start_panel', :id => params[:supervisor_id]
  end

=begin
    @api {post} /supervisor_runs Start SupervisorRun
    @apiName supervisor_runs#create
    @apiGroup SupervisorRuns
    @apiDescription This action allows user to start new supervisor with given parameters.

    @apiParam {String} supervisor_id ID of supervisor to be started
    @apiParam {Object} config json object with config of supervisor run, serialized to string
    @apiParam {String} config.experiment_id ID of experiment to be managed
    @apiParam {String} config.user Username used in authentication in Experiment Manager
    @apiParam {String} config.password Password used in authentication in Experiment Manager
    @apiParam {Number[]} config.parameters list of simulation parameters
    @apiParam {Number[]} config.parameters.type parameter type
    @apiParam {Number[]} config.parameters.id parameter id
    @apiParam {Number[]} [config.parameters.min] parameter minimum value, only for type int and float
    @apiParam {Number[]} [config.parameters.max] parameter maximum value, only for type int and float
    @apiParam {Number[]} [config.parameters.allowed_vales] list of possible values, only for type string
    @apiParam {Number[]} [config.parameters.start_value] start value for given parameter

    @apiParamExample Params-Example
    supervisor_id: 'simulated annealing'
    config:
    {
      maxiter: 1,
      dwell: 1,
      schedule: 'boltzmann',
      experiment_id: '551fca1f2ab4f259fc000002',
      user: 'user',
      password: 'password',
      parameters : [
          {
              type: 'float',
              id: 'c___g___x',
              min: -3,
              max: 3,
              start_value: 0
          },
          {
              type: 'int',
              id: 'c___g___y',
              min: -2,
              max: 2,
              start_value: 0
          },
          {
              type: 'string',
              id: 'c___g___z',
              allowed_values: [aaa, bbb, ccc],
              start_value: 'aaa'
          }
      ]
    }

    @apiSuccess {Object} info json object with information about performed action
    @apiSuccess {String} info.status status of performed action, on success always 'ok'
    @apiSuccess {Number} info.pid pid of supervisor run managing experiment
    @apiSuccess {String} info.supervisor_run_id id of new supervisor run

    @apiSuccessExample {json} Success-Response
    {
      'status': 'ok'
      'pid': 1234
      'supervisor_run_id': 'id'
    }

    @apiError {Object} info json object with information about performed action
    @apiError {String} info.status status of performed action, on failure always 'error'
    @apiError {String} info.reason reason of failure to start supervisor script

    @apiErrorExample {json} Failure-Response
    {
        'status': 'error'
        'reason': 'Unable to locate supervisor script files'
    }
=end
  def create
    # TODO: security
    # config.user -> maybe we should check if SimulationManagerTempPassword (or user) belongs to @current_user
    #  because no one could invoke supervisor on behalf of other user
    config = Scalarm::ServiceCore::Utils::parse_json_if_string(params[:config])
    experiment_id = config['experiment_id'].to_s

    begin
      BSON::ObjectId(experiment_id)
    rescue BSON::InvalidObjectId
      precondition_failed
    end

    Rails.logger.debug "Will create supervisor run for experiment: #{experiment_id}"

    # check if experiment is visible to current user
    experiment = Scalarm::Database::Model::Experiment.where(
        {'_id' => experiment_id},
        fields: %w(user_id shared_with)).first

    resource_not_found unless experiment

    resource_forbidden unless ((experiment.shared_with || []) + [experiment.user_id]).include? current_user.id

    #TODO validate and check errors
    response = {}
    begin
      supervisor_run = SupervisorRun.new({})
      # TODO: params[:config] can be not only JSON but also Hash (parsed by Rails)
      pid = supervisor_run.start (params[:supervisor_id] || params[:id]), experiment_id, current_user.id, config
      supervisor_run.save
      Rails.logger.debug supervisor_run
      response = {status: 'ok', pid: pid, supervisor_run_id: supervisor_run.id.to_s}

    rescue StandardError => e
      Rails.logger.debug("Error while starting new supervisor script: #{e.to_s}")
      response.merge!({status: 'error', reason: "[Experiment Supervisor] #{e.to_s}"})
      supervisor_run.destroy
    end

    render json: response
  end

  def show
    render json: @supervisor_run.state
  end

  def stop
    @supervisor_run.stop
    @supervisor_run.save
    render json: {status: 'ok'}
  end

  def destroy
    @supervisor_run.destroy
    render json: {status: 'ok'}
  end

  def load_supervisor_run
    @supervisor_run = SupervisorRun.find_by_id(params[:id]) || resource_not_found

    experiment = Scalarm::Database::Model::Experiment.where(
        {'_id' => @supervisor_run.experiment_id},
        fields: %w(user_id shared_with)).first
    resource_forbidden unless ((experiment.shared_with || []) + [experiment.user_id]).include? current_user.id
  end

  def check_supervisor_owners
    supervisor_owners = [@supervisor_run.user_id]
    supervisor_owners << Scalarm::Database::Model::Experiment.where(
        {'_id' => @supervisor_run.experiment_id},
        fields: 'user_id').first.user_id
    supervisor_owners.uniq!
    resource_forbidden unless supervisor_owners.include? current_user.id
  end

  private :load_supervisor_run, :check_supervisor_owners

end
