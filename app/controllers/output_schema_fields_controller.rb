class OutputSchemaFieldsController < ApplicationController
  before_action :set_output_schema_field, only: [:show, :edit, :update, :destroy]

  # GET /output_schema_fields
  # GET /output_schema_fields.json
  def index
    @output_schema_fields = OutputSchemaField.all
  end

  # GET /output_schema_fields/1
  # GET /output_schema_fields/1.json
  def show
  end

  # GET /output_schema_fields/new
  def new
    @output_schema_field = OutputSchemaField.new
  end

  # GET /output_schema_fields/1/edit
  def edit
  end

  # POST /output_schema_fields
  # POST /output_schema_fields.json
  def create
    @output_schema_field = OutputSchemaField.new(output_schema_field_params)

    respond_to do |format|
      if @output_schema_field.save
        format.html { redirect_to @output_schema_field, notice: 'Output schema field was successfully created.' }
        format.json { render :show, status: :created, location: @output_schema_field }
      else
        format.html { render :new }
        format.json { render json: @output_schema_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /output_schema_fields/1
  # PATCH/PUT /output_schema_fields/1.json
  def update
    respond_to do |format|
      if @output_schema_field.update(output_schema_field_params)
        format.html { redirect_to @output_schema_field, notice: 'Output schema field was successfully updated.' }
        format.json { render :show, status: :ok, location: @output_schema_field }
      else
        format.html { render :edit }
        format.json { render json: @output_schema_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /output_schema_fields/1
  # DELETE /output_schema_fields/1.json
  def destroy
    @output_schema_field.destroy
    respond_to do |format|
      format.html { redirect_to output_schema_fields_url, notice: 'Output schema field was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_output_schema_field
      @output_schema_field = OutputSchemaField.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def output_schema_field_params
      params.fetch(:output_schema_field, {})
    end
end
