class DatasetsController < ApplicationController
  include FileHandlingForDatasets

  before_action :redirect_to_api, only: [:index, :show, :files, :dashboard]
  before_action :get_dataset, only: [:show, :files, :edit, :destroy]
  before_action :get_multipart, only: [:create, :update]
  before_action :clear_files, only: [:create, :update]
  before_action :process_files, only: [:create, :update]
  before_action :check_mandatory_fields, only: [:create]
  before_action :set_licenses, only: [:create, :new, :edit, :update]
  before_action :set_direct_post, only: [:edit, :new]
  before_action(only: :index) { alternate_formats [:json, :feed] }

  authorize_resource

  skip_before_action :verify_authenticity_token, only: [:create, :update], if: Proc.new { !current_user.nil? }

  def index
    @title = "Public Datasets"
    @datasets = Dataset.github_public.order(created_at: :desc)
  end

  def dashboard
    @title = "My Datasets"
    @datasets = current_user.datasets
  end

  def organisation_index
    organisation_name = params[:organisation_name]
    @title = "#{organisation_name.titleize}'s Datasets"
    @datasets = Dataset.where(owner: organisation_name)
    render :index
  end

  def user_datasets
    @datasets = current_user.datasets
    render :dashboard
  end

  def refresh
    User.delay.refresh_datasets(current_user.id, params[:channel_id])
    head :accepted
  end

  def created
    @publishing_method = params[:publishing_method]
    logger.info "DatasetsController: In created for publishing_method #{@publishing_method}"
  end

  def edited
    logger.info "DatasetsController: In edited"
  end

  def new
    logger.info "DatasetsController: In new"
    @dataset = Dataset.new
    @dataset_file_schemas = available_schemas
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
    @dataset_file_schemas = available_schemas
    @users = User.all
    @default_schema = @dataset.dataset_files.first.try(:dataset_file_schema_id)
  end

  def show
  end

  def update
    logger.info "DatasetsController: In update"
    files_array = get_files_as_array_for_serialisation
    UpdateDataset.perform_async(params["id"], dataset_update_params.to_h, files_array, channel_id: params[:channel_id])

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

  def dataset_update_params
    params[:dataset].try(:permit, [:user_id, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :publishing_method])
  end

  def set_direct_post
    @s3_direct_post = FileStorageService.private_presigned_post
  end

  def available_schemas
    DatasetFileSchema.where(user_id: current_user.id).or(DatasetFileSchema.where(restricted: false))
  end
end
