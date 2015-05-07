Rails.application.routes.draw do

  resources :supervisor_runs, except: [:update, :edit] do
    member do
      post :stop
    end
  end
  resources :supervisors, only: [:index, :show] do
    member do
      get 'new', to: 'supervisors#new_member'
      post :create, to: 'supervisors#create_member'
    end
  end

end
