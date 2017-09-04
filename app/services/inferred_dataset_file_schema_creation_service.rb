require 'ostruct'

class InferredDatasetFileSchemaCreationService

  def initialize(inferred_dataset_file_schema)
    @inferred_dataset_file_schema = inferred_dataset_file_schema
    @csv_storage_key = sort_out_csv_storage_key(@inferred_dataset_file_schema.csv_url)
  end

  def sort_out_csv_storage_key(csv_storage_url_or_file)
    if [ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile].include?(csv_storage_url_or_file.class)
      Rails.logger.info "file is an Http::UploadedFile (non javascript?)"
      storage_object = FileStorageService.create_and_upload_public_object(@inferred_dataset_file_schema.name, csv_storage_url_or_file.read)
      storage_object.key(csv_storage_url_or_file.original_filename)
    else
      Rails.logger.info "file is not an http uploaded file, it's a URL"
      FileStorageService.get_storage_key_from_public_url(csv_storage_url_or_file)
    end
  end

  def self.infer_dataset_file_schema_from_csv(csv_storage_key)
    data = CSV.parse(FileStorageService.get_string_io(csv_storage_key))
    headers = data.shift
    inferer = JsonTableSchema::Infer.new(headers, data, explicit: true)
    inferer.schema
  end

  def perform
    begin
      inferred_schema = self.class.infer_dataset_file_schema_from_csv(@csv_storage_key)
      user = User.find(@inferred_dataset_file_schema.user_id)
      storage_object = FileStorageService.create_and_upload_public_object(inferred_schema_filename(@inferred_dataset_file_schema.name), inferred_schema.to_json)
      dataset_file_schema = user.dataset_file_schemas.create(
        url_in_s3: storage_object.public_url,
        storage_key: storage_object.key,
        name: @inferred_dataset_file_schema.name,
        description: @inferred_dataset_file_schema.description,
        schema: inferred_schema.to_json,
        owner_username: @inferred_dataset_file_schema.owner_username,
        restricted: @inferred_dataset_file_schema.restricted,
        schema_category_ids: @inferred_dataset_file_schema.schema_category_ids
      )
      DatasetFileSchemaService.update_dataset_file_schema(dataset_file_schema)
    rescue => exception
      OpenStruct.new(success?: false, dataset_file_schema: dataset_file_schema, error: exception)
    else
      OpenStruct.new(success?: true, dataset_file_schema: dataset_file_schema)
    end
  end

  def inferred_schema_filename(schema_name)
    "#{schema_name.parameterize}.json"
  end
end
