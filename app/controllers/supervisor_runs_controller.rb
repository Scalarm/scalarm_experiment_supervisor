require 'json'

class SupervisorRunsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    # TODO
  end

  def new
    # TODO
  end

=begin
    @api {post} /start_supervisor_script.json Start Supervisor Script
    @apiName start_supervisor_script
    @apiGroup SupervisorScripts
    @apiDescription This action allows user to start new supervisor script with given parameters.

    @apiParam {String} script_id ID of supervisor script to be started
    @apiParam {Object} config json object with config of supervisor script, serialized to string
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
    script_id: 'simulated annealing'
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
    @apiSuccess {Number} info.pid pid of supervisor script managing experiment

    @apiSuccessExample {json} Success-Response
    {
      'status': 'ok'
      'pid': 1234
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
    #TODO validate and check errors
    response = {}
    begin
      supervisor_run = SupervisorRun.new({})
      pid = supervisor_run.start params[:script_id], JSON.parse(params[:config])
      supervisor_run.save
      Rails.logger.debug supervisor_run
      response = {status: 'ok', pid: pid}

    rescue StandardError => e
      Rails.logger.debug("Error while starting new supervisor script: #{e.to_s}")
      response.merge!({status: 'error', reason: "[Experiment Supervisor] #{e.to_s}"})
      supervisor_run.destroy
    end

    render json: response
  end

  def show
    # TODO
  end

  def stop
    # TODO
  end

  def destroy
    # TODO
  end

end
