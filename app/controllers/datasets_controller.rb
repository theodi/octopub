class DatasetsController < ApplicationController

  before_filter :check_signed_in?, only: [:edit, :dashboard, :update]
  before_filter :get_dataset, only: [:edit, :update]
  before_filter :handle_files, only: [:create, :update]
  before_filter :set_licenses, only: [:create, :new, :edit]
  before_filter(only: :index) { alternate_formats [:json, :feed] }

  def index
    @datasets = Dataset.all
  end

  def dashboard
    current_user.refresh_datasets if params[:refresh]
    @datasets = current_user.datasets
  end

  def new
    @dataset = Dataset.new
  end

  def create
    @dataset = current_user.datasets.new(dataset_params)
    @dataset.save
    @dataset.add_files(params["files"])
    redirect_to datasets_path, :notice => "Dataset created sucessfully"
  end

  def edit
    @dataset = current_user.datasets.where(id: params["id"]).first
    render_404 and return if @dataset.nil?
  end

  def update
    p = dataset_params
    p.delete(:name)
    @dataset.update(p)
    @dataset.update_files(params["files"])
    redirect_to datasets_path, :notice => "Dataset updated sucessfully"
  end

  private

  def get_dataset
    @dataset = Dataset.where(id: params["id"], user_id: current_user.id).first
  end

  def handle_files
    clear_files
    check_files
  end

  def clear_files
    params["files"].delete_if { |f| f["file"].blank? && f["title"].blank? }
  end

  def check_files
    if params["files"].count == 0
      flash[:notice] = "You must specify at least one dataset"
      render "new"
    end
  end

  def set_licenses
    @licenses = [
                  "cc-by",
                  "cc-by-sa",
                  "cc0",
                  "OGL-UK-3.0",
                  "odc-by",
                  "odc-pddl"
                ].map do |id|
                  license = Odlifier::License.define(id)
                  [license.title, license.id]
                end
  end

  def dataset_params
    params.require(:dataset).permit(:name, :description, :publisher_name, :publisher_url, :license, :frequency)
  end

  def check_signed_in?
    render_404 if current_user.nil?
  end

end
