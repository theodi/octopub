module FileHandlingForDatasets
  extend ActiveSupport::Concern

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

  def get_files_as_array_for_serialisation
    @files.map { |file_param_object| file_param_object.to_unsafe_hash }
  end

  def get_dataset
    @dataset = Dataset.find(params["id"])
  end

  def clear_files
    @files.keep_if { |f| f["id"] || (f["file"] && f["title"]) }
  end

  def dataset_params
    params.require(:dataset).permit(:name, :owner, :description, :publisher_name, :publisher_url, :license, :frequency, :schema, :schema_name, :schema_description, :schema_restricted, :dataset_file_schema_id, :publishing_method)
  end
end
