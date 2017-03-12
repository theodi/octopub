require 'ostruct'

class InferredDatasetFileSchemaCreationService

  def initialize(inferred_dataset_file_schema)
    @inferred_dataset_file_schema = inferred_dataset_file_schema
    @csv_storage_key = sort_out_storage_key(@inferred_dataset_file_schema.csv_url)
  end

  def sort_out_storage_key(csv_url)
    ap csv_url
    FileStorageService.get_storage_key_from_public_url(csv_url)
  end

  def self.infer_dataset_file_schema_from_csv(csv_storage_key)
    data = CSV.parse(FileStorageService.get_string_io(csv_storage_key))
    headers = data.shift
    inferer = JsonTableSchema::Infer.new(headers, data, explicit: true)
    schema = inferer.schema
  end

  def perform
    begin
      inferred_schema = self.class.infer_dataset_file_schema_from_csv(@csv_storage_key)
      user = User.find(@inferred_dataset_file_schema.user_id)
      storage_object = FileStorageService.create_and_upload_public_object(inferred_schema_filename(@inferred_dataset_file_schema.name), inferred_schema.to_json)
      dataset_file_schema = user.dataset_file_schemas.create(url_in_s3: storage_object.public_url, storage_key: storage_object.key, name: @inferred_dataset_file_schema.name, description: @inferred_dataset_file_schema.description, schema: inferred_schema.to_json)
    rescue => exception
      OpenStruct.new(success?: false, dataset_file_schema: dataset_file_schema, error: exception)
    else
      OpenStruct.new(success?: true, dataset_file_schema: dataset_file_schema)
    end
  end

  def upload_inferred_schema_to_s3(inferred_schema, filename)
    obj = FileStorageService.create_and_upload_public_object(filename, inferred_schema)
    obj
  end

  def inferred_schema_filename(schema_name)
    "#{schema_name.parameterize}.json"
  end

end
