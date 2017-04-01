class DatasetFilesController < ApplicationController

  def index
    dataset_id = params[:dataset_id]
    @dataset = Dataset.find(dataset_id)
    @dataset_files = DatasetFile.where(dataset_id: dataset_id)
  end
end