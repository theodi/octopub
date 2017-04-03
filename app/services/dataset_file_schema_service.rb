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
    @dataset_file_schema.reload
    unless @dataset_file_schema.csv_on_the_web_schema
      self.class.populate_schema_fields_and_constraints(@dataset_file_schema)
      @dataset_file_schema.update(schema: @dataset_file_schema.to_builder.target!)
    end
    @dataset_file_schema
  end

  def self.update_dataset_file_schema_with_json_schema(dataset_file_schema)
    Rails.logger.info "URL #{dataset_file_schema.url_in_s3}"
    dataset_file_schema.update(schema: load_json_from_s3(dataset_file_schema.url_in_s3))
    dataset_file_schema.update(csv_on_the_web_schema: dataset_file_schema.is_schema_otw?)
  end

  def self.update_dataset_file_schema(dataset_file_schema)
    storage_key = FileStorageService.get_storage_key_from_public_url(dataset_file_schema.url_in_s3)
    dataset_file_schema.update(storage_key: storage_key)
    update_dataset_file_schema_with_json_schema(dataset_file_schema)
    populate_schema_fields_and_constraints(dataset_file_schema)
  end

  def self.load_json_from_s3(url_in_s3)
    Rails.logger.info "URL #{url_in_s3}"
    JSON.generate(JSON.load(read_file_with_utf_8(url_in_s3)))
  end

  def self.parse_schema(schema_string)
    JsonTableSchema::Schema.new(JSON.parse(schema_string))
  end

  def self.read_file_with_utf_8(url)
    open(url).read.force_encoding("UTF-8")
  end

  def self.get_parsed_schema_from_csv_lint(url)
    Csvlint::Schema.load_from_json(url)
  end

  def self.populate_schema_fields_and_constraints(dataset_file_schema)
    Rails.logger.info "in populate_schema_fields_and_constraints"
    if dataset_file_schema.schema_fields.empty? && dataset_file_schema.schema.present?
      Rails.logger.info "in populate_schema_fields_and_constraints - we have no fields and schema, so crack on"
      dataset_file_schema.json_table_schema['fields'].each do |field|
        Rails.logger.info "in populate_schema_fields_and_constraints #{field}"
        unless field['constraints'].nil?
          field['schema_constraint_attributes'] = field['constraints']
          field.delete('constraints')
        end
        dataset_file_schema.schema_fields.create(field)
      end
    end
  end
end
