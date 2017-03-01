class DatasetFileSchemasInferenceController < ApplicationController
  def new
    @dataset_file_schema = DatasetFileSchema.new
    @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
  end

  def create

    ap create_params
    user = User.find(create_params[:user_id])
    schema_name = create_params[:name]
    description = create_params[:description]
    @dataset_file_schema = DatasetFileSchemaService.new.infer_and_create_dataset_file_schema(create_params[:url_in_s3], user, schema_name, description)

    #@dataset_file_schema = DatasetFileSchema.new(create_params)
    # if @dataset_file_schema.save
    #   DatasetFileSchemaService.new(@dataset_file_schema).update_dataset_file_schema_with_json_schema
      redirect_to dataset_file_schemas_path
    # else
    #   @s3_direct_post = S3_BUCKET.presigned_post(bucket_attributes)
    #   render :new
    # end
  end

  private

  def bucket_attributes
    { key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read' }
  end

  def create_params
    params.require(:dataset_file_schema).permit(:name, :description, :user_id, :url_in_s3)
  end
end
