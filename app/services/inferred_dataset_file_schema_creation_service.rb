class InferredDatasetFileSchemaCreationService

  def initialize(inferred_dataset_file_schema)
    @inferred_dataset_file_schema = inferred_dataset_file_schema
  end

  def self.infer_dataset_file_schema_from_csv(csv_url)
    data = CSV.parse(read_file_with_utf_8(csv_url))
    headers = data.shift
    inferer = JsonTableSchema::Infer.new(headers, data, explicit: true)
    schema = inferer.schema
  end

  def perform
    inferred_schema = self.class.infer_dataset_file_schema_from_csv(@inferred_dataset_file_schema.csv_url)
    user = User.find(@inferred_dataset_file_schema.user_id)
    url_in_s3 = upload_inferred_schema_to_s3(inferred_schema.to_json, inferred_schema_filename(@inferred_dataset_file_schema.name))
    user.dataset_file_schemas.create(url_in_s3: url_in_s3.public_url, name: @inferred_dataset_file_schema.name, description: @inferred_dataset_file_schema.description, schema: inferred_schema.to_json)
  end


  def upload_inferred_schema_to_s3(inferred_schema, filename)
    key = object_key(filename)
    obj = S3_BUCKET.object(key)
    obj.put(body: inferred_schema)
    obj
  end

  def inferred_schema_filename(schema_name)
    "#{schema_name.parameterize}.json"
  end

  private

  def self.read_file_with_utf_8(url)
    open(url).read.force_encoding("UTF-8")
  end


  def object_key(filename)
    "uploads/#{SecureRandom.uuid}/#{filename}"
  end
end
