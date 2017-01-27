class DatasetSchemaService

  def initialize(dataset_file_schema = nil)
    @dataset_file_schema = dataset_file_schema
  end

  def create_dataset_file_schema(url_in_s3, user = nil)
    @dataset_file_schema = DatasetFileSchema.new(url_in_s3: url_in_s3)
    @dataset_file_schema.user = user if user

    update_dataset_file_schema_with_json_schema
    @dataset_file_schema
  end

  def create_dataset_file_schema_for_user(user, url_in_s3)
    user.dataset_file_schemas.create(url_in_s3: url_in_s3)
  end

  def update_dataset_file_schema_with_json_schema
    schema_from_s3 = read_file_with_utf_8(@dataset_file_schema.url_in_s3)
    @dataset_file_schema.update(schema: schema_from_s3)
  end

  def read_file_with_utf_8(url)
    open(url).read.force_encoding("UTF-8")
  end

  def self.get_parsed_schema_from_csv_lint(url)
    Csvlint::Schema.load_from_json(url)
  end

end
