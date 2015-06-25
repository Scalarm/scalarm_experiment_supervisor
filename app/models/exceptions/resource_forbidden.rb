class ResourceForbidden < ActionController::ActionControllerError
  def status
    :forbidden
  end
end