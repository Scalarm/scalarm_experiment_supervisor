require 'json'

class SupervisorScriptController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new
  end

  # POST params
  # - supervisor_script_id
  # - supervisor_script_params
  # - experiment_input
  #TODO validate and check errors
  def create
    response = {}
    begin
      supervisor_script = SupervisorScript.new(
                              params[:id],
                              JSON.parse(params[:config]),
                              JSON.parse(params[:experiment_input])
      )
      supervisor_script.start
      # supervisor_script.save TODO
      response = {status: 'ok', pid: supervisor_script.pid}

    rescue Exception => e
      Rails.logger.debug("Error while starting new supervisor script: #{e}")
      response.merge!({status: 'error', reason: e.to_s})
    end

    render json: response
  end
end
