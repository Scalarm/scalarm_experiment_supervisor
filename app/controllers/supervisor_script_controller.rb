require 'json'

class SupervisorScriptController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

  # POST params
  # - script_id
  # - config
  #TODO validate and check errors
  def create
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
