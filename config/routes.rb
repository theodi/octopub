Rails.application.routes.draw do

  root 'application#index'

  get "/auth/:provider/callback" => "sessions#create", :as => :callback
  get "/signout" => "sessions#destroy", :as => :signout
  get "/redirect" => "sessions#redirect", :as => :redirect

  resources :datasets do
    collection do
      get "/refresh", action: 'refresh'
    end
    member do
      get "/files", action: :files
    end
  end

  get "/dashboard" => "datasets#dashboard", :as => :dashboard

  get "/me" => "users#edit", as: :me
  put "/me" => "users#update"
  get "/user/organizations" => "users#organizations", as: :user_organizations

end
