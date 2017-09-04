class PopulateNewSchemaField < ActiveRecord::Migration[5.0]
  def change
    DatasetFileSchema.all.each do |dataset_file_schema| 
      ap dataset_file_schema
      begin    
        dataset_file_schema.update(csv_on_the_web_schema: true) if dataset_file_schema.is_schema_otw? 
      rescue OpenURI::HTTPError
        Rails.logger.warn "Cannot update this one as Schema cannot be accessed in S3 #{dataset_file_schema.id}"
      end
    end
  end
end
