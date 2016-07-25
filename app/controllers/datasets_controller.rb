class DatasetsController < ApplicationController

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
    respond_to do |format|
      format.html do
        @datasets = Dataset.paginate(page: params[:page], per_page: 7).order(created_at: :desc)
      end

      format.json do
        @datasets = Dataset.all.order(created_at: :desc)
      end
    end
  end

  def dashboard
    @dashboard = true

    respond_to do |format|
      format.html do
        @datasets = current_user.all_datasets.paginate(page: params[:page])
      end

      format.json do
        @datasets = current_user.all_datasets

        render json: {
          datasets: @datasets.map { |d| dataset_presenter(d) }
        }
      end
    end
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
      respond_to do |format|
        format.html do
          redirect_to created_datasets_path
        end

        format.json do
          render json: {
            job_url: job_url(job)
          }, status: 202
        end
      end
    end
  end

  def edit
    render_404 and return if @dataset.nil?
  end

  def show
    render_404 and return if @dataset.nil?

    respond_to do |format|
      format.json do
        render json: dataset_presenter(@dataset)
      end
    end
  end

  def files
    render_404 and return if @dataset.nil?

    respond_to do |format|
      format.json do
        render json: @dataset.dataset_files.map { |f| file_presenter(f) }
      end
    end
  end

  def update
    job = UpdateDataset.perform_async(params["id"], current_user.id, dataset_update_params, params[:files], channel_id: params[:channel_id])

    if params[:async]
      head :accepted
    else
      respond_to do |format|
        format.html do
          redirect_to edited_datasets_path
        end

        format.json do
          render json: {
            job_url: job_url(job)
          }, status: 202
        end
      end
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

  def dataset_presenter(dataset)
    license = Odlifier::License.define(dataset.license)
    {
      id: dataset.id,
      url: dataset_url(dataset),
      name: dataset.name,
      description: dataset.description,
      publisher: {
        name: dataset.publisher_name,
        url: dataset.publisher_url
      },
      license: {
        id: license.id,
        title: license.title,
        url: license.url
      },
      frequency: dataset.frequency,
      owner: dataset.owner,
      github_url: dataset.url,
      gh_pages_url: dataset.gh_pages_url,
      certificate_url: dataset.certificate_url,
      files: dataset.dataset_files.map { |f| file_presenter(f) }
    }
  end

  def file_presenter(file)
    {
      id: file.id,
      title: file.title,
      description: file.description,
      filename: file.filename,
      github_url: file.github_url
    }
  end

end
