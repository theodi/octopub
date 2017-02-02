class DatasetFileSchemaService

  def create_dataset_file_schema(schema_name, description, url_in_s3, user = nil)
    Rails.logger.info "In create #{url_in_s3}"
    unless user.nil?
      @dataset_file_schema = user.dataset_file_schemas.create(url_in_s3: url_in_s3, name: schema_name, description: description)
    else
      @dataset_file_schema = DatasetFileSchema.new(url_in_s3: url_in_s3, name: schema_name, description: description)
    end
    update_dataset_file_schema_with_json_schema
    @dataset_file_schema
  end

  def update_dataset_file_schema_with_json_schema
    Rails.logger.info "URL #{@dataset_file_schema.url_in_s3}"
    @dataset_file_schema.update(schema: load_json_from_s3)
  end

  def load_json_from_s3
    Rails.logger.info "URL #{@dataset_file_schema.url_in_s3}"
    JSON.generate(JSON.load(read_file_with_utf_8(@dataset_file_schema.url_in_s3)))
  end

  def read_file_with_utf_8(url)
    open(url).read.force_encoding("UTF-8")
  end

  def self.get_parsed_schema_from_csv_lint(url)
    Csvlint::Schema.load_from_json(url)
  end

end
