class DatasetFileSchemasController < ApplicationController

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).paginate(page: params[:page], per_page: 7).order(name: :asc)
  end

  def new
    render status: :forbidden, plain: "Forbidden fruit"
  end

  def create
    render status: :forbidden, plain: "Forbidden fruit"
  end
end
