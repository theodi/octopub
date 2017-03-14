class InferredDatasetFileSchemasController < ApplicationController

  # TODO needs to handle files and URLs like Dataset controller

  def new
    @inferred_dataset_file_schema = InferredDatasetFileSchema.new
    @s3_direct_post = FileStorageService.presigned_post
  end

  def create
    # TODO refactor this logic, it's a bit messy at the moment
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
    @s3_direct_post = FileStorageService.presigned_post
    render :new
  end

  def create_params
    params.require(:inferred_dataset_file_schema).permit(:name, :description, :user_id, :csv_url)
  end
end
