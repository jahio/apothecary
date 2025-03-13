Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  post "/events" => "inventory_events#create", as: :create_inventory_event

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # good_job dashboard - go to /good_job
  mount GoodJob::Engine => 'good_job'

  # Defines the root path route ("/")
  # root "posts#index"
end
