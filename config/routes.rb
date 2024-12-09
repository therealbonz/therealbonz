Rails.application.routes.draw do
  
  resources :pins
get '/pins/show', to: 'pins#show'
get '/pins/create', to: 'pins#create'
get '/pins/update', to: 'pins#update'
get '/pins/edit', to: 'pins#edit'
get '/pins/index', to: 'pins#index'
get '/pins/:id', to: 'pins#destroy'
get '/pins/new', to: 'pins#new'

devise_for :users, path: 'auth', path_names: { sign_in: 'login', sign_out: 'logout', password: 'secret', confirmation: 'verification', unlock: 'unblock', registration: 'register', sign_up: 'cmon_let_me_in' }

devise_scope :user do
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
 get '/auth/logout' => 'devise/sessions#destroy'
end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
   root "pins#index"
end
