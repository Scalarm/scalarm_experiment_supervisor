Rails.application.routes.draw do
  get 'start_supervisor_script' => 'supervisor_scripts#new'
  post 'start_supervisor_script' => 'supervisor_scripts#create'

end
