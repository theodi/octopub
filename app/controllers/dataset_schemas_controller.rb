class DatasetSchemasController < ApplicationController

  def index
    @dataset_schemas = DatasetSchema.paginate(page: params[:page], per_page: 7).order(name: :asc)
  end
end
