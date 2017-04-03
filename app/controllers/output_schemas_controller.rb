class OutputSchemasController < ApplicationController
  before_action :set_output_schema, only: [:show, :edit, :update, :destroy]

  # GET /output_schemas
  # GET /output_schemas.json
  def index
    @output_schemas = OutputSchema.all
  end

  # GET /output_schemas/1
  # GET /output_schemas/1.json
  def show
  end

  # GET /output_schemas/new
  def new
    @dataset_file_schema = DatasetFileSchema.find(params[:dataset_file_schema_id])
    output_schema_fields = @dataset_file_schema.schema_fields.map { |schema_field| OutputSchemaField.new(schema_field: schema_field) }

    @output_schema = OutputSchema.new(dataset_file_schema: @dataset_file_schema,  output_schema_fields: output_schema_fields)
  end

  # GET /output_schemas/1/edit
  def edit
  end

  # POST /output_schemas
  # POST /output_schemas.json
  def create
    @output_schema = OutputSchema.new(output_schema_params)

    respond_to do |format|
      if @output_schema.save
        format.html { redirect_to dataset_file_schema_output_schema_path(@output_schema.dataset_file_schema, @output_schema), notice: 'Output schema was successfully created.' }
        format.json { render :show, status: :created, location: @output_schema }
      else
        format.html { render :new }
        format.json { render json: @output_schema.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /output_schemas/1
  # PATCH/PUT /output_schemas/1.json
  def update
    respond_to do |format|
      if @output_schema.update(output_schema_params)
        format.html { redirect_to dataset_file_schema_output_schema_path(@output_schema.dataset_file_schema, @output_schema), notice: 'Output schema was successfully updated.' }
        format.json { render :show, status: :ok, location: @output_schema }
      else
        format.html { render :edit }
        format.json { render json: @output_schema.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /output_schemas/1
  # DELETE /output_schemas/1.json
  def destroy
    @output_schema.destroy
    respond_to do |format|
      format.html { redirect_to output_schemas_url, notice: 'Output schema was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_output_schema
    @output_schema = OutputSchema.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def output_schema_params
    params.require(:output_schema).permit(:user_id, :title, :description, :owner_username, :dataset_file_schema_id, output_schema_fields_attributes: [ :aggregation_type] )
  end
end
