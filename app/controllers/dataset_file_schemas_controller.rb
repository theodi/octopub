class DatasetFileSchemasController < ApplicationController

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).paginate(page: params[:page], per_page: 7).order(name: :asc)
  end

  def new
    @dataset_file_schema = DatasetFileSchema.new
    @s3_direct_post = S3_BUCKET.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read')
   # render status: :forbidden, plain: "Forbidden fruit"
  end

  def create
    @dataset_file_schema = DatasetFileSchema.new(create_params)
    if @dataset_file_schema.save
      redirect_to dataset_file_schemas_path
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:dataset_file_schema).permit(:name, :description, :user_id, :url)
  end

      def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :restricted)
  end
end
