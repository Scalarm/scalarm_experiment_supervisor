class SupervisorsController < ApplicationController

  def index
    render json: Supervisor.get_maniphests
  end

  def show
    render json: Supervisor.get_maniphest(params[:id]) || not_found
  end

  def new_member
    # TODO
  end

  def create_member
    # TODO
  end
end
