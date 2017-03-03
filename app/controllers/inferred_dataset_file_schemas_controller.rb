class InferredDatasetFileSchemasController < ApplicationController

  def new
    @inferred_dataset_file_schema = InferredDatasetFileSchema.new
    @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
  end

  def create
    @inferred_dataset_file_schema = InferredDatasetFileSchema.new(create_params)
    if @inferred_dataset_file_schema.valid? && InferredDatasetFileSchemaCreationService.new(@inferred_dataset_file_schema).perform.success?
      redirect_to dataset_file_schemas_path
    else
      failed_create
    end
  end

  private

  def failed_create
    @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
    render :new
  end

  def bucket_attributes
    { key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read' }
  end

  def create_params
    params.require(:inferred_dataset_file_schema).permit(:name, :description, :user_id, :csv_url)
  end
end
