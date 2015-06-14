class ResourceForbidden < ActionController::ActionControllerError
  def status
    403
  end
end