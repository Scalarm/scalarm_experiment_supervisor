class PreconditionFailed < ActionController::ActionControllerError
  def status
    :precondition_failed
  end
end