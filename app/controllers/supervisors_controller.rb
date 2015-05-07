class SupervisorsController < ApplicationController

  def index
    render json: Supervisor.get_maniphests
  end

  def show
    render json: Supervisor.get_maniphest(params[:id]) || not_found
  end

  def start_panel
    render Supervisor.view_path(params[:id]) || not_found, layout: false
  end
end
