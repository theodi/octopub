class DatasetFileSchemasController < ApplicationController
  before_action :check_signed_in?
  before_action :set_dataset_file_schema, only: [:show, :edit, :update, :destroy]

  def index
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).order(created_at: :desc)
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
    @dataset_file_schema = DatasetFileSchema.new(create_params)
    if @dataset_file_schema.save
      DatasetFileSchemaService.update_dataset_file_schema_with_json_schema(@dataset_file_schema)
      redirect_to dataset_file_schemas_path
    else
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
      @schema_fields = @dataset_file_schema.schema_fields
      @dataset_file_schema.update(schema: @dataset_file_schema.to_builder.target!)
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

  def create_params
    params.require(:dataset_file_schema).permit(:name, :description, :user_id, :url_in_s3, :owner_username, schema_category_ids: [])
  end

  def update_params
    params.require(:dataset_file_schema).permit(
      schema_fields_attributes: [ :id, :name, :type, :format, schema_constraint_attributes:
        [:id, :required, :unique, :min_length, :max_length, :minimum, :maximum, :pattern, :type]])
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
