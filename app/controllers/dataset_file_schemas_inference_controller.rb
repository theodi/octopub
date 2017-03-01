class DatasetFileSchemasInferenceController < ApplicationController
  def new
    @dataset_file_schema = DatasetFileSchema.new
    @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
  end

  def create
    user = User.find(create_params[:user_id])
    schema_name = create_params[:name]
    description = create_params[:description]

    @dataset_file_schema = DatasetFileSchemaService.new.infer_and_create_dataset_file_schema(
      create_params[:url_in_s3],
      user,
      schema_name,
      description
    )

    redirect_to dataset_file_schemas_path
  end

  private

  def bucket_attributes
    { key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read' }
  end

  def create_params
    params.permit(:name, :description, :user_id, :url_in_s3)
  end
end
