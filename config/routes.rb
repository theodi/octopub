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

  resources :dataset_file_schemas, only: [:index, :new, :create]
  resources :inferred_dataset_file_schemas, only: [:new, :create]
  # get '/dataset_file_schemas/infer/new' => 'dataset_file_schemas_inference#new', as: :new_infer_dataset_file_schema
  # post '/dataset_file_schemas/infer' => 'dataset_file_schemas_inference#create'


  resources :dataset_file_schemas, only: [:index, :new, :create, :show]
  resources :jobs, only: [:show]

  get "/dashboard" => "datasets#dashboard", :as => :dashboard

  get "/me" => "users#edit", as: :me
  put "/me" => "users#update"
  get "/licenses" => "application#licenses"

  mount API => '/'
  mount GrapeSwaggerRails::Engine => '/api'

end
