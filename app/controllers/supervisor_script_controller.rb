require 'json'

class SupervisorScriptController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

  # POST params
  # - supervisor_script_id
  # - supervisor_script_params
  #TODO validate and check errors
  def create
    response = {}
    begin
      supervisor_script = SupervisorScript.new({})
      pid = supervisor_script.start params[:script_id], JSON.parse(params[:config])
      Rails.logger.debug supervisor_script
      supervisor_script.save
      response = {status: 'ok', pid: pid}

    rescue Exception => e
      Rails.logger.debug("Error while starting new supervisor script: #{e.to_s}")
      response.merge!({status: 'error', reason: "[Experiment Supervisor] #{e.to_s}"})
    end

    render json: response
  end
end
