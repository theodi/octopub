class DatasetFileSchemaService

  def initialize(schema_name, description, url_in_s3, user, owner_username = user.name)
    @schema_name = schema_name
    @description = description
    @url_in_s3 = url_in_s3
    @user = user
    @owner_username = owner_username
  end

  def create_dataset_file_schema
    Rails.logger.info "In create #{@url_in_s3}"

    FileStorageService.make_object_public_from_url(@url_in_s3)

    @dataset_file_schema = @user.dataset_file_schemas.create(url_in_s3: @url_in_s3, name: @schema_name, description: @description, owner_username: @owner_username)
    self.class.update_dataset_file_schema_with_json_schema(@dataset_file_schema)
    @dataset_file_schema.create_associated_fields_from_schema
    @dataset_file_schema
  end

  def self.update_dataset_file_schema_with_json_schema(dataset_file_schema)
    Rails.logger.info "URL #{dataset_file_schema.url_in_s3}"
    dataset_file_schema.update(schema: load_json_from_s3(dataset_file_schema.url_in_s3))
  end

  def self.load_json_from_s3(url_in_s3)
    Rails.logger.info "URL #{url_in_s3}"
    JSON.generate(JSON.load(read_file_with_utf_8(url_in_s3)))
  end

  def self.read_file_with_utf_8(url)
    open(url).read.force_encoding("UTF-8")
  end

  def self.get_parsed_schema_from_csv_lint(url)
    Csvlint::Schema.load_from_json(url)
  end
end
