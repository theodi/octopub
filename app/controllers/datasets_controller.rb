class DatasetsController < ApplicationController

  before_filter :check_signed_in?, only: [:edit, :dashboard, :update, :create, :new]
  before_filter :get_dataset, only: [:edit, :update]
  before_filter :handle_files, only: [:create, :update]
  before_filter :set_licenses, only: [:create, :new, :edit]
  before_filter(only: :index) { alternate_formats [:json, :feed] }

  skip_before_filter :verify_authenticity_token, only: :create, if: Proc.new { !current_user.nil? }

  def index
    @datasets = Dataset.all
  end

  def dashboard
    current_user.refresh_datasets if params[:refresh]
    @datasets = current_user.datasets
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
        response = (@dataset.attributes).merge({
          gh_pages_url: @dataset.gh_pages_url
        })
        render json: response.to_json
      end
    end
  end

  def edit
    @dataset = current_user.datasets.where(id: params["id"]).first
    render_404 and return if @dataset.nil?
  end

  def update
    p = dataset_params
    p.delete(:name)
    @dataset.fetch_repo
    @dataset.assign_attributes(p)

    params[:files].each do |file|
      if file["id"]
        DatasetFile.update_file(file)
      else
        file = DatasetFile.new_file file
        @dataset.dataset_files << file
        file.add_to_github
      end
    end

    @dataset.save
    redirect_to datasets_path, :notice => "Dataset updated sucessfully"
  end

  private

  def get_dataset
    @dataset = Dataset.where(id: params["id"], user_id: current_user.id).first
  end

  def handle_files
    clear_files
    check_files
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
    params.require(:dataset).permit(:name, :description, :publisher_name, :publisher_url, :license, :frequency)
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end

end
