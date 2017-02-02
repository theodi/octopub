class DatasetFileSchemasController < ApplicationController

  def index
    @dataset_file_schemas = DatasetFileSchema.paginate(page: params[:page], per_page: 7).order(name: :asc)
  end
end
