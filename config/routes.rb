Rails.application.routes.draw do

  root 'application#index'

  get '/api-docs' => 'application#api'#, :as => :api

  get "/auth/:provider/callback" => "sessions#create", :as => :callback
  get "/signout" => "sessions#destroy", :as => :signout
  get "/redirect" => "sessions#redirect", :as => :redirect

  resources :datasets do
    collection do
      get "/refresh", action: 'refresh'
      get "/created", action: 'created'
      get "/edited", action: 'edited'
    end
    member do
      get "/files", action: :files
    end
  end

  resources :jobs, only: [:show]

  get "/dashboard" => "datasets#dashboard", :as => :dashboard

  get "/me" => "users#edit", as: :me
  put "/me" => "users#update"
  get "/licenses" => "application#licenses"

  mount API => '/'
  mount GrapeSwaggerRails::Engine => '/api'

end
