class DatasetsController < ApplicationController

  before_action :redirect_to_api, only: [:index, :show, :files, :dashboard]
  before_action :check_signed_in?, only: [:show, :files, :edit, :dashboard, :update, :create, :new]
  before_action :check_permissions, only: [:show, :files, :edit, :update, :delete]
  before_action :get_dataset, only: [:show, :files, :edit, :destroy]
  before_action :get_multipart, only: [:create, :update]
  before_action :clear_files, only: [:create, :update]
  before_action :process_files, only: [:create, :update]
  before_action :check_mandatory_fields, only: [:create]
  before_action :set_licenses, only: [:create, :new, :edit, :update]
  before_action :set_direct_post, only: [:edit, :new]
  before_action(only: :index) { alternate_formats [:json, :feed] }

  skip_before_action :verify_authenticity_token, only: [:create, :update], if: Proc.new { !current_user.nil? }

  def index
    @title = "Public Datasets"
    @datasets = Dataset.github_public.order(created_at: :desc)
  end

  def dashboard
    @title = "My Datasets"
    @dashboard = true
    @datasets = current_user.datasets
  end

  def organisation_index
    organisation_name = params[:organisation_name]
    @title = "#{organisation_name.titleize}'s Datasets"
    @datasets = Dataset.where(owner: organisation_name)
    render :index
  end

  def user_datasets
    @title = "My Datasets"
    @dashboard = true
    @datasets = current_user.datasets
    render :dashboard
  end

  def refresh
    User.delay.refresh_datasets(current_user.id, params[:channel_id])
    head :accepted
  end

  def created
    @publishing_method = params[:publishing_method]
    logger.info "DatasetsController: In created for publishing_method #{}"
  end

  def edited
    logger.info "DatasetsController: In edited"
  end

  def new
    logger.info "DatasetsController: In new"
    @dataset = Dataset.new
    @dataset_file_schemas = DatasetFileSchema.where(user_id: current_user.id)
  end

  def create
    logger.info "DatasetsController: In create"
    files_array = get_files_as_array_for_serialisation
    CreateDataset.perform_async(dataset_params.to_h, files_array, current_user.id, channel_id: params[:channel_id])

    if params[:async]
      logger.info "DatasetsController: In create with params aysnc"
      head :accepted
    else
      redirect_to created_datasets_path(publishing_method: dataset_params[:publishing_method])
    end
  end

  def edit
    render_404 and return if @dataset.nil?
  end

  def show
  end

  def update
    logger.info "DatasetsController: In update"
    files_array = get_files_as_array_for_serialisation
    UpdateDataset.perform_async(params["id"], current_user.id, dataset_update_params.to_h, files_array, channel_id: params[:channel_id])

    if params[:async]
      head :accepted
    else
      redirect_to edited_datasets_path
    end
  end

  def destroy
    success_message = "Dataset '#{@dataset.name}' deleted sucessfully"
    begin
      RepoService.fetch_repo(@dataset) unless @dataset.local_private?
    rescue Octokit::NotFound
      Rails.logger.info "Cannot find repository, probably already deleted"
      success_message = "#{success_message} - but we could not find the repository in GitHub to delete"
    end
    @dataset.destroy
    redirect_to dashboard_path, notice: success_message
  end

  private

  def get_files_as_array_for_serialisation
    @files.map { |file_param_object| file_param_object.to_unsafe_hash }
  end

  def get_dataset
    @dataset = Dataset.find(params["id"])
  end

  def clear_files
    @files.keep_if { |f| f["id"] || (f["file"] && f["title"]) }
  end

  def check_mandatory_fields
    logger.info "DatasetsController: In check_mandatory_fields"
    check_files
    check_publisher
    render 'new' unless flash.empty?
  end

  def check_publisher
    if params[:dataset][:publisher_name].blank?
      flash[:no_publisher] = "Please include the name of the publisher"
    end
  end

  def check_files
    if @files.blank?
      flash[:no_files] = "You must specify at least one dataset"
    end
  end

  def process_files
    logger.info "DatasetsController: In process_files"
    @files.each do |f|

      if [ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile].include?(f["file"].class)
        Rails.logger.info "file is an Http::UploadedFile (non javascript?)"
        storage_object = FileStorageService.create_and_upload_public_object(f["file"].original_filename, f["file"].read)

        f["storage_key"] = storage_object.key(f["file"].original_filename)
        f["file"] = storage_object.public_url
      else
        Rails.logger.info "file is not an http uploaded file, it's a URL"
        f["storage_key"] = URI(f["file"]).path.gsub(/^\//, '') unless f["file"].nil?
      end
    end
  end

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :publishing_method)
  end

  def dataset_update_params
    params[:dataset].try(:permit, [:description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :publishing_method])
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end

  def set_direct_post
    @s3_direct_post = FileStorageService.private_presigned_post
  end

  def check_permissions
    render_403 unless current_user.all_dataset_ids.include?(params[:id].to_i)
  end

  def get_multipart

    @files = params["files"] || Array.new

    if params["data"]
      data = ActiveSupport::HashWithIndifferentAccess.new JSON.parse(params.delete("data"))
      params["dataset"] = data["dataset"]

      data["files"].each_with_index do |f, i|
        @files[i]["title"] = f["title"]
        @files[i]["description"] = f["description"]
      end
    end
  end

  def redirect_to_api
    if params[:format] == 'json'
      api_routes = {
        "index" => "/api/datasets",
        "dashboard" => "/api/user/datasets",
        "show" => "/api/datasets/#{params[:id]}",
        "files" => "/api/datasets/#{params[:id]}/files"
      }

      route = api_routes[params[:action]]
      redirect_to(route) if route.present?
    end
  end

end
