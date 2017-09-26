class DatasetFileSchemasController < ApplicationController
  before_action :set_dataset_file_schema, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).order(created_at: :desc)
    @public_schemas = DatasetFileSchema.where(restricted: false).order(created_at: :desc)
  end

  def show
    @dataset_file_schema = DatasetFileSchema.find(params[:id])
    if @dataset_file_schema.schema
      json = JSON.parse(@dataset_file_schema.schema)
      @json_table_schema = JsonTableSchema::Schema.new(json)
    end
  end

  def new
    @dataset_file_schema = DatasetFileSchema.new
    @user_id = current_user.id
    @s3_direct_post = FileStorageService.presigned_post
  end

  def create
    process_file
    @dataset_file_schema = DatasetFileSchemaService.create(create_params)
    if @dataset_file_schema && @dataset_file_schema.valid?
      redirect_to dataset_file_schemas_path
    else
      @dataset_file_schema ||= DatasetFileSchema.new
      @s3_direct_post = FileStorageService.presigned_post
      @user_id = current_user.id
      render :new
    end
  end

  def edit
    json = JSON.parse(@dataset_file_schema.schema)
    @dataset_file_schema = create_empty_constraints_for_edit(@dataset_file_schema)
    @json_table_schema = JsonTableSchema::Schema.new(json)
  end

  def update
    if @dataset_file_schema.update(update_params)

      schema = @dataset_file_schema.to_builder.target!
      @dataset_file_schema.update(schema: schema)
      FileStorageService.push_public_object(@dataset_file_schema.storage_key, schema)
      redirect_to dataset_file_schema_path(@dataset_file_schema)
    else
      render :edit
    end
  end

  def destroy
    @dataset_file_schema.destroy
    redirect_to dataset_file_schemas_path, :notice => "Dataset File Schema '#{@dataset_file_schema.name}' deleted sucessfully"
  end

  private

  def process_file
    file_reference = params["dataset_file_schema"]["url_in_s3"]
    return if file_reference.nil?

    # Check to see whether it's a file rather than a URL
    if [ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile].include?(file_reference.class)

      Rails.logger.info "file is an Http::UploadedFile"
      storage_object = FileStorageService.create_and_upload_public_object(file_reference.original_filename, file_reference.read)

      params["dataset_file_schema"]["storage_key"] = storage_object.key
      params["dataset_file_schema"]["url_in_s3"] = storage_object.public_url
    else
      Rails.logger.info "file is not an http uploaded file, it's a URL"
      params["dataset_file_schema"]["storage_key"] = FileStorageService.get_storage_key_from_public_url(file_reference)
    end
  end

  def update_dataset_file_schema(dataset_file_schema)
    @dataset_file_schema.update(storage_key: URI(dataset_file_schema.url_in_s3).path.gsub(/^\//, ''))
    DatasetFileSchemaService.update_dataset_file_schema_with_json_schema(@dataset_file_schema)
    DatasetFileSchemaService.populate_schema_fields_and_constraints(@dataset_file_schema)
  end

  def create_params
    params.require(:dataset_file_schema).permit(:name, :description, :user_id, :url_in_s3, :owner_username, :storage_key, :restricted, schema_category_ids: [])
  end

  def update_params
    params.require(:dataset_file_schema).permit(
      :restricted, 
      schema_fields_attributes: [ :id, :name, :type, :format, schema_constraint_attributes:
        [:id, :required, :unique, :min_length, :max_length, :minimum, :maximum, :pattern, :date_pattern, :type]])
  end

  def create_empty_constraints_for_edit(dataset_file_schema)
    dataset_file_schema.schema_fields.each do |schema_field|
      schema_field.schema_constraint = SchemaConstraint.new({}) unless schema_field.schema_constraint
    end
    dataset_file_schema
  end

  def set_dataset_file_schema
    @dataset_file_schema = DatasetFileSchema.find(params[:id])
  end

end
