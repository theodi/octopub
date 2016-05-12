Rails.application.routes.draw do

  root 'application#index'

  get "/auth/:provider/callback" => "sessions#create", :as => :callback
  get "/signout" => "sessions#destroy", :as => :signout

  resources :datasets

  get "/dashboard" => "datasets#dashboard", :as => :dashboard

end
