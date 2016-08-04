class DatasetsController < ApplicationController

  before_filter :redirect_to_api, only: [:index, :show, :files, :dashboard]
  before_filter :check_signed_in?, only: [:show, :files, :edit, :dashboard, :update, :create, :new]
  before_filter :check_permissions, only: [:show, :files, :edit, :update, :delete]
  before_filter :get_dataset, only: [:show, :files, :edit, :destroy]
  before_filter :get_multipart, only: [:create, :update]
  before_filter :clear_files, only: [:create, :update]
  before_filter :process_files, only: [:create, :update]
  before_filter :check_files, only: [:create]
  before_filter :set_licenses, only: [:create, :new, :edit, :update]
  before_filter :set_direct_post, only: [:edit, :new]
  before_filter(only: :index) { alternate_formats [:json, :feed] }

  skip_before_filter :verify_authenticity_token, only: [:create, :update], if: Proc.new { !current_user.nil? }

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
  end

  def create
    job = CreateDataset.perform_async(dataset_params, params["files"], current_user.id, channel_id: params[:channel_id])

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
    job = UpdateDataset.perform_async(params["id"], current_user.id, dataset_update_params, params[:files], channel_id: params[:channel_id])

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

  def get_dataset
    @dataset = Dataset.find(params["id"])
  end

  def clear_files
    params["files"].keep_if { |f| f["id"] || (f["file"] && f["title"]) }
  end

  def check_files
    if params["files"].count == 0
      flash[:notice] = "You must specify at least one dataset"
      render "new"
    end
  end

  def process_files
    params["files"].each do |f|
      if [ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile].include?(f["file"].class)
        key ="uploads/#{SecureRandom.uuid}/#{f["file"].original_filename}"
        obj = S3_BUCKET.object(key)
        obj.put(body: f["file"].read, acl: 'public-read')
        f["file"] = obj.public_url
      end
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

  def set_direct_post
    @s3_direct_post = S3_BUCKET.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read')
  end

  def check_permissions
    render_403 unless current_user.all_dataset_ids.include?(params[:id].to_i)
  end

  def get_multipart
    if params["data"]
      data = ActiveSupport::HashWithIndifferentAccess.new JSON.parse(params.delete("data"))
      params["dataset"] = data["dataset"]

      data["files"].each_with_index do |f, i|
        params["files"][i]["title"] = f["title"]
        params["files"][i]["description"] = f["description"]
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
