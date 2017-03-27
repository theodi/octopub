Rails.application.routes.draw do


  root 'application#index'

  get '/api-docs' => 'application#api'#, :as => :api

  get "/auth/:provider/callback" => "sessions#create", :as => :callback
  get "/signout" => "sessions#destroy", :as => :signout
  get "/redirect" => "sessions#redirect", :as => :redirect

  resources :datasets, except: [:index, :create] do
    collection do

      get "/refresh", action: 'refresh'
      get "/created", action: 'created'
      get "/edited", action: 'edited'
    end
    member do
      get "/files", action: :files
    end

  end

  get "/datasets" => 'datasets_index#index', as: :datasets
  post "/datasets" => 'datasets#create'
  get "/dashboard" => "datasets_index#dashboard", :as => :dashboard
  get "/organisation/:organisation_name/datasets" => "datasets_index#organisation_index", as: :organisation_datasets
  get "/user/:user_id/datasets" => "datasets_index#user_datasets", as: :user_datasets

  resources :dataset_file_schemas, only: [:index, :new, :create, :show, :destroy]

  get "/dataset_file_schemas/:dataset_file_schema_id/datasets/new" => "allocated_dataset_file_schema_datasets#new", as: :new_dataset_file_schema_dataset
  post "/dataset_file_schemas/:dataset_file_schema_id/datasets" => "allocated_dataset_file_schema_datasets#create", as: :dataset_file_schema_datasets

  resources :inferred_dataset_file_schemas, only: [:new, :create]
  resources :jobs, only: [:show]
  resources :users, only: [:index, :show, :edit ,:update]
  resources :restricted_users, only: [:edit, :update]
  resources :schema_categories, except: :show

  get "/me" => "users#edit", as: :me
  put "/me" => "users#update"
  get "/licenses" => "application#licenses"

  mount API => '/'
  mount GrapeSwaggerRails::Engine => '/api'

end
