class DatasetFileSchemasController < ApplicationController

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).order(created_at: :desc)
  end

  def show
    @dataset_file_schema = DatasetFileSchema.find(params[:id])
  end

  def new
    @dataset_file_schema = DatasetFileSchema.new
    @s3_direct_post = FileStorageService.presigned_post
  end

  def create
    @dataset_file_schema = DatasetFileSchema.new(create_params)
    if @dataset_file_schema.save

      DatasetFileSchemaService.update_dataset_file_schema_with_json_schema(@dataset_file_schema)
      redirect_to dataset_file_schemas_path
    else
      @s3_direct_post = FileStorageService.presigned_post
      render :new
    end
  end

  private

  def create_params
    params.require(:dataset_file_schema).permit(:name, :description, :user_id, :url_in_s3)
  end

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :restricted)
  end
end
