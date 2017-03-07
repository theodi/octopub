class InferredDatasetFileSchemasController < ApplicationController

  def new
    @inferred_dataset_file_schema = InferredDatasetFileSchema.new
    @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
  end

  def create
    @inferred_dataset_file_schema = InferredDatasetFileSchema.new(create_params)

    if @inferred_dataset_file_schema.valid?
      creation_result = InferredDatasetFileSchemaCreationService.new(@inferred_dataset_file_schema).perform
      if creation_result.success?
        redirect_to dataset_file_schemas_path
      else
        Rails.logger.info "failed to create, no success #{creation_result.error} "
        @inferred_dataset_file_schema.errors.add(:csv_url, "Inferring schema from dataset failed: #{creation_result.error}")
        failed_create
      end
    else
      Rails.logger.info "failed to validate dataset file schema"
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
