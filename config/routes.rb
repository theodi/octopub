Rails.application.routes.draw do

  root 'application#index'

  get "/auth/:provider/callback" => "sessions#create", :as => :callback
  get "/signout" => "sessions#destroy", :as => :signout
  get "/redirect" => "sessions#redirect", :as => :redirect

  resources :datasets

  get "/dashboard" => "datasets#dashboard", :as => :dashboard

end
