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
    @datasets = Dataset.paginate(page: params[:page], per_page: 7).order(created_at: :desc)
  end

  def dashboard
    @dashboard = true
    @datasets = current_user.all_datasets.paginate(page: params[:page])
  end

  def refresh
    User.delay.refresh_datasets(current_user.id, params[:channel_id])

    head :accepted
  end

  def created
  end

  def edited
  end

  def new
    @dataset = Dataset.new
    @dataset_file_schemas = DatasetFileSchema.where(user_id: current_user.id)
  end

  def create
    files_array = get_files_as_array_for_serialisation
    job = CreateDataset.perform_async(dataset_params.to_h, files_array, current_user.id, channel_id: params[:channel_id])

    if params[:async]
      head :accepted
    else
      redirect_to created_datasets_path
    end
  end

  def edit
    render_404 and return if @dataset.nil?
  end

  def show
  end

  def update
    files_array = get_files_as_array_for_serialisation
    job = UpdateDataset.perform_async(params["id"], current_user.id, dataset_update_params.to_h, files_array, channel_id: params[:channel_id])

    if params[:async]
      head :accepted
    else
      redirect_to edited_datasets_path
    end
  end

  def destroy
    @dataset.fetch_repo
    @dataset.destroy
    redirect_to dashboard_path, :notice => "Dataset '#{@dataset.name}' deleted sucessfully"
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
    @files.each do |f|
      if [ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile].include?(f["file"].class)
        key ="uploads/#{SecureRandom.uuid}/#{f["file"].original_filename}"
        obj = S3_BUCKET.object(key)
        obj.put(body: f["file"].read, acl: 'public-read')
        f["file"] = obj.public_url
      end
    end
  end

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id)
  end

  def dataset_update_params
    params[:dataset].try(:permit, [:description, :publisher_name, :publisher_url, :license, :frequency, :schema])
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end

  def set_direct_post
    @s3_direct_post = S3_BUCKET.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read')
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
