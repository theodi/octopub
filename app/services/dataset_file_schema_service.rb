class DatasetFileSchemaService

  def self.create(create_options)
    # name:, 
    # description:, 
    # url_in_s3:, 
    # storage_key: nil, 
    # user:, 
    # owner_username: nil, 
    # restricted: true, 
    # schema_category_ids: []
    
    Rails.logger.info "In create #{create_options[:url_in_s3]}"

    user = create_options[:user] || User.find(create_options[:user_id]) rescue nil
    return nil unless user
    
    create_options[:owner_username] ||= user.name
    create_options[:storage_key] ||= FileStorageService.get_storage_key_from_public_url(create_options[:url_in_s3])

    dataset_file_schema = user.dataset_file_schemas.create(create_options)

    if dataset_file_schema.valid?
      FileStorageService.make_object_public_from_url(create_options[:url_in_s3])    
      update_dataset_file_schema_with_json_schema(dataset_file_schema)
      dataset_file_schema.reload
      unless dataset_file_schema.csv_on_the_web_schema
        populate_schema_fields_and_constraints(dataset_file_schema)
        dataset_file_schema.update(schema: dataset_file_schema.to_builder.target!)
      end
    end
    dataset_file_schema
  end

  def self.update_dataset_file_schema_with_json_schema(dataset_file_schema)
    Rails.logger.info "Key #{dataset_file_schema.storage_key}"
    if dataset_file_schema.schema.nil?
      dataset_file_schema.update(schema: load_json_from_s3(dataset_file_schema.storage_key))
    end
    dataset_file_schema.update(csv_on_the_web_schema: dataset_file_schema.is_schema_otw?)
  end

  def self.update_dataset_file_schema(dataset_file_schema)
    storage_key = FileStorageService.get_storage_key_from_public_url(dataset_file_schema.url_in_s3)
    dataset_file_schema.update(storage_key: storage_key)
    update_dataset_file_schema_with_json_schema(dataset_file_schema)
    populate_schema_fields_and_constraints(dataset_file_schema)
  end

  def self.load_json_from_s3(storage_key)
    Rails.logger.info "DatasetFileSchemaService#load_json_from_s3 #{storage_key}"
    JSON.generate(JSON.load(read_file_with_utf_8(storage_key)))
  end

  def self.parse_schema(schema_string)
    JsonTableSchema::Schema.new(JSON.parse(schema_string))
  end

  def self.read_file_with_utf_8(storage_key)
    Rails.logger.info "DatasetFileSchemaService#read_file_with_utf_8 #{storage_key}"
    FileStorageService.get_string_io(storage_key).read.force_encoding("UTF-8")
  end

  def self.get_parsed_schema_from_csv_lint(url)
    begin
      output = Csvlint::Schema.load_from_json(url)
    rescue Exception => e
      Rails.logger.error "Unable to parse schema #{url}"
    end
    output
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
