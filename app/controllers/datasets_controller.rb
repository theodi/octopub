class DatasetsController < ApplicationController

  before_filter :check_signed_in?, only: [:edit, :dashboard, :update, :create, :new]
  before_filter :get_dataset, only: [:edit, :update]
  before_filter :clear_files, only: [:create, :update]
  before_filter :check_files, only: [:create]
  before_filter :set_licenses, only: [:create, :new, :edit, :update]
  before_filter(only: :index) { alternate_formats [:json, :feed] }

  skip_before_filter :verify_authenticity_token, only: [:create, :update], if: Proc.new { !current_user.nil? }

  def index
    @datasets = Dataset.all
  end

  def dashboard
    current_user.refresh_datasets if params[:refresh]
    @datasets = current_user.datasets

    respond_to do |format|
      format.html

      format.json do
        render json: {
          datasets: @datasets
        }.to_json
      end
    end
  end

  def new
    @dataset = Dataset.new
  end

  def create
    @dataset = current_user.datasets.new(dataset_params)
    params["files"].each do |file|
      @dataset.dataset_files << DatasetFile.new_file(file)
    end

    respond_to do |format|
      format.html do
        if @dataset.save
          redirect_to datasets_path, :notice => "Dataset created sucessfully"
        else
          generate_errors
          render :new
        end
      end

      format.json do
        if @dataset.save
          response = (@dataset.attributes).merge({
            gh_pages_url: @dataset.gh_pages_url
          })
          render json: response.to_json
        else
          render json: {
            errors: generate_errors
          }.to_json
        end
      end
    end
  end

  def edit
    @dataset = current_user.datasets.where(id: params["id"]).first
    render_404 and return if @dataset.nil?
  end

  def update
    @dataset.fetch_repo
    @dataset.assign_attributes(dataset_update_params) if dataset_update_params

    params[:files].each do |file|
      if file["id"]
        f = @dataset.dataset_files.find { |f| f.id == file["id"].to_i }
        f.update_file(file)
      else
        f = DatasetFile.new_file(file)
        @dataset.dataset_files << f
        if f.save
          f.add_to_github
          f.file = nil
        end
      end
    end

    respond_to do |format|
      format.html do
        if @dataset.save
          redirect_to datasets_path, :notice => "Dataset updated sucessfully"
        else
          generate_errors
          render :edit, status: 400
        end
      end

      format.json do
        if @dataset.save
          response = (@dataset.attributes).merge({
            gh_pages_url: @dataset.gh_pages_url
          })
          render json: response.to_json, status: 201
        else
          render json: {
            errors: generate_errors
          }.to_json, status: 400
        end
      end
    end
  end

  private

  def get_dataset
    @dataset = Dataset.where(id: params["id"], user_id: current_user.id).first
  end

  def clear_files
    params["files"].delete_if { |f| f["file"].blank? && f["title"].blank? }
  end

  def check_files
    if params["files"].count == 0
      flash[:notice] = "You must specify at least one dataset"
      render "new"
    end
  end

  def set_licenses
    @licenses = [
                  "cc-by",
                  "cc-by-sa",
                  "cc0",
                  "OGL-UK-3.0",
                  "odc-by",
                  "odc-pddl"
                ].map do |id|
                  license = Odlifier::License.define(id)
                  [license.title, license.id]
                end
  end

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema)
  end

  def dataset_update_params
    params[:dataset].try(:permit, [:description, :publisher_name, :publisher_url, :license, :frequency, :schema])
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end

  def generate_errors
    messages = []
    @dataset.dataset_files.each do |file|
      messages << "Your file '#{file.title}' does not match the schema you provided" unless file.valid?
    end
    if params["format"] == "json"
      messages
    else
      flash[:notice] = messages.join('<br>')
    end
  end

end
