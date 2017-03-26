class SchemaCategoriesController < ApplicationController
  before_action :set_schema_category, only: [:show, :edit, :update, :destroy]

  # GET /schema_categories
  # GET /schema_categories.json
  def index
    @schema_categories = SchemaCategory.all
  end

  # GET /schema_categories/1
  # GET /schema_categories/1.json
  def show
  end

  # GET /schema_categories/new
  def new
    @schema_category = SchemaCategory.new
  end

  # GET /schema_categories/1/edit
  def edit
  end

  # POST /schema_categories
  # POST /schema_categories.json
  def create
    @schema_category = SchemaCategory.new(schema_category_params)

    respond_to do |format|
      if @schema_category.save
        format.html { redirect_to schema_categories_path, notice: 'Schema category was successfully created.' }
        format.json { render :show, status: :created, location: @schema_category }
      else
        format.html { render :new }
        format.json { render json: @schema_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /schema_categories/1
  # PATCH/PUT /schema_categories/1.json
  def update
    respond_to do |format|
      if @schema_category.update(schema_category_params)
        format.html { redirect_to schema_categories_path, notice: 'Schema category was successfully updated.' }
        format.json { render :show, status: :ok, location: @schema_category }
      else
        format.html { render :edit }
        format.json { render json: @schema_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schema_categories/1
  # DELETE /schema_categories/1.json
  def destroy
    @schema_category.destroy
    respond_to do |format|
      format.html { redirect_to schema_categories_url, notice: 'Schema category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_schema_category
      @schema_category = SchemaCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def schema_category_params
      params.fetch(:schema_category).permit(:name, :description)
    end
end
