class DatasetsController < ApplicationController

  def index
    @datasets = current_user.datasets
  end

  def new
    @dataset = Dataset.new
  end

  def create
    dataset = current_user.datasets.create(name: params["dataset"]["name"])
    dataset.add_files(params["files"]) unless params["files"].nil?
    redirect_to datasets_path, :notice => "Dataset created sucessfully"
  end

end
