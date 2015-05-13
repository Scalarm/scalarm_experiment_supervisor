Rails.application.routes.draw do

  resources :supervisor_runs, except: [:update, :edit] do
    member do
      post :stop
    end
  end
  resources :supervisors, only: [:index, :show] do
    member do
      get :start_panel, to: 'supervisors#start_panel'
      post :create_run, to: 'supervisor_runs#create'
    end
  end

end
