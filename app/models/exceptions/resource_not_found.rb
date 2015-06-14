class ResourceNotFound < ActionController::RoutingError
  def status
    404
  end
end