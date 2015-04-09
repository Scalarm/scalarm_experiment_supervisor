require 'json'

class SupervisorScriptsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

=begin
    @api {post} /start_supervisor_script.json Start Supervisor Script
    @apiName start_supervisor_script
    @apiGroup SupervisorScripts
    @apiDescription This action allows user to start new supervisor script with given parameters.

    @apiParam {String} script_id ID of supervisor script to be started
    @apiParam {Object} config json object with config of supervisor script
    @apiParam {String} config.experiment_id ID of experiment to be managed
    @apiParam {String} config.user Username used in authentication in Experiment Manager
    @apiParam {String} config.password Password used in authentication in Experiment Manager
    @apiParam {Number[]} config.lower_limits Lower boundary of experiment input space
    @apiParam {Number[]} config.upper_limits Upper boundary of experiment input space
    @apiParam {String[]} config.parameter_ids IDs of input space parameter in correct order
    @apiParam {Number[]} config.start_point Start point of supervisor script

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
      lower_limit: [-2, -3],
      upper_limit: [2, 3],
      parameters_ids: [c___g___x, c___g___y],
      start_point: [0, 0]
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
      supervisor_script = SupervisorScript.new({})
      pid = supervisor_script.start params[:script_id], JSON.parse(params[:config])
      supervisor_script.save
      Rails.logger.debug supervisor_script
      response = {status: 'ok', pid: pid}

    rescue StandardError => e
      Rails.logger.debug("Error while starting new supervisor script: #{e.to_s}")
      response.merge!({status: 'error', reason: "[Experiment Supervisor] #{e.to_s}"})
      supervisor_script.destroy
    end

    render json: response
  end
end
