class DatasetsController < ApplicationController

  before_filter :clear_files, only: :create
  before_filter :set_licenses, only: [:create, :new]
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
    params["files"].each { |f| @dataset.dataset_files.new(f) }
    if params["files"].count == 0
      flash[:notice] = "You must specify at least one dataset"
      render "new"
    elsif @dataset.valid?
      @dataset.save
      redirect_to datasets_path, :notice => "Dataset created sucessfully"
    else
      render "new"
    end
  end

  private

  def clear_files
    params["files"].delete_if { |f| f["file"].nil? }
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
    params.require(:dataset).permit(:name, :description, :publisher_name, :publisher_url, :license, :frequency, :files)
  end

end
