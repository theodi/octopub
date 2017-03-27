class DatasetsIndexController < ApplicationController
  include FileHandlingForDatasets

  before_action :redirect_to_api
  before_action :check_signed_in?, except: :index
#  before_action :check_permissions, except: :index
  before_action(only: :index) { alternate_formats [:json, :feed] }

  def index
    @title = "Public Datasets"
    @datasets = Dataset.github_public.order(created_at: :desc)
  end

  def dashboard
    ap "HELLO"
    @title = "My Datasets"
    @dashboard = true
    @datasets = current_user.datasets
    render 'datasets/dashboard'
  end

  def organisation_index
    organisation_name = params[:organisation_name]
    @title = "#{organisation_name.titleize}'s Datasets"
    @datasets = Dataset.where(owner: organisation_name)
    render :index
  end

  def user_datasets
    @title = "My Datasets"
    @dashboard = true
    @datasets = current_user.datasets
    render 'datasets/dashboard'
#    render :dashboard
  end

  private

  def check_signed_in?
    ap current_user
    render_403 if current_user.nil?
  end

  def check_permissions
    render_403 unless current_user.all_dataset_ids.include?(params[:id].to_i)
  end
end
