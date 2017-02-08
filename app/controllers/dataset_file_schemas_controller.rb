class DatasetFileSchemasController < ApplicationController

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).paginate(page: params[:page], per_page: 7).order(name: :asc)
  end
end
