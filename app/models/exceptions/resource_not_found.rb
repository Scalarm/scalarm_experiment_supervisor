class ResourceNotFound < ActionController::RoutingError
  def status
    :not_found
  end
end