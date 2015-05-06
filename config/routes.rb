Rails.application.routes.draw do
  resources :supervisor_runs, only: [:create, :new]

end
