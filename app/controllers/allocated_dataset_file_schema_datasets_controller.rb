class AllocatedDatasetFileSchemaDatasetsController < ApplicationController

  before_action :check_signed_in?
  before_action :check_permissions
  before_action :get_multipart, only: :create
  before_action :clear_files, only: :create
  before_action :process_files, only: :create
  before_action :check_mandatory_fields, only: :create
  before_action :set_direct_post, only: :new

  def new
    logger.info "AllocatedDatasetFileSchemaDatasetsController: In new"
    @dataset = Dataset.new#(
    #   publishing_method: :local_private,
    #   publisher_name: current_user.name,
    #   owner: current_user.name)
    @dataset_file_schema_id = params[:dataset_file_schema_id]
    @dataset_file_schema = DatasetFileSchema.find(@dataset_file_schema_id)
  end


  def create
    logger.info "AllocatedDatasetFileSchemaDatasetsController: In create"
    dataset_params_hash = dataset_params.to_h
    dataset_params_hash[:publishing_method] = :local_private
    dataset_params_hash[:publisher_name] = current_user.name
    dataset_params_hash[:owner] = current_user.name


    files_array = get_files_as_array_for_serialisation

    CreateDataset.perform_async(dataset_params_hash, files_array, current_user.id, channel_id: params[:channel_id])

    if params[:async]
      logger.info "DatasetsController: In create with params aysnc"
      head :accepted
    else
      redirect_to created_datasets_path
    end
  end

  private

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :dataset_file_schema_id, :publishing_method)
  end

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
    render 'new' unless flash.empty?
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




  def check_signed_in?
    render_403 if current_user.nil?
  end

  def set_direct_post
    @s3_direct_post = FileStorageService.private_presigned_post
  end

  def check_permissions
   # render_403 unless current_user.all_dataset_ids.include?(params[:id].to_i)
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
