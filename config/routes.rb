Rails.application.routes.draw do
  resources :videos
  # Resources for pins, adding the remove_image route for each pin
  resources :pins do
    get 'remove_image', on: :member # For removing an image from a pin
  end

  # Devise routes for user authentication
  devise_for :users, path: 'auth', path_names: { sign_in: 'login', sign_out: 'logout', password: 'secret', confirmation: 'verification', unlock: 'unblock', registration: 'register', sign_up: 'cmon_let_me_in' }

  devise_scope :user do
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    get '/auth/logout' => 'devise/sessions#destroy'
  end

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Define the root path route
  root "pins#index"
end