Rails.application.routes.draw do
  get 'start_supervisor_script' => 'supervisor_script#new'
  post 'start_supervisor_script' => 'supervisor_script#create'

end
