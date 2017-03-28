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
  end

  get "/datasets/:dataset_id/dataset_files" => "dataset_files#index", as: :files
  get "/dataset_files/:id/download" => "dataset_files#download", as: :dataset_file_download

  resources :dataset_file_schemas do
    resources :output_schemas, except: [:index, :show, :destroy, :edit, :update]
  end
  resources :output_schemas, only: [:index, :show, :destroy, :edit, :update]

  get "/dataset_file_schemas/:dataset_file_schema_id/datasets/new" => "allocated_dataset_file_schema_datasets#new", as: :new_dataset_file_schema_dataset
  post "/dataset_file_schemas/:dataset_file_schema_id/datasets" => "allocated_dataset_file_schema_datasets#create", as: :dataset_file_schema_datasets

  resources :inferred_dataset_file_schemas, only: [:new, :create]
  resources :jobs, only: [:show]
  resources :users, only: [:index, :show, :edit ,:update]
  resources :restricted_users, only: [:edit, :update]
  resources :schema_categories, except: :show

  get "/dashboard" => "datasets#dashboard", :as => :dashboard
  get "/organisation/:organisation_name/datasets" => "datasets#organisation_index", as: :organisation_datasets
  get "/user/:user_id/datasets" => "datasets#user_datasets", as: :user_datasets

  get "/me" => "users#edit", as: :me
  put "/me" => "users#update"
  get "/licenses" => "application#licenses"
  get "/getting-started" => "application#getting_started"

  mount API => '/'
  mount GrapeSwaggerRails::Engine => '/api'

end
