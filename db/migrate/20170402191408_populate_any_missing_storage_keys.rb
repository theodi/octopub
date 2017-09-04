class PopulateAnyMissingStorageKeys < ActiveRecord::Migration[5.0]
  def change
    DatasetFileSchema.where(storage_key: nil).each do |schema|
      schema.update(storage_key: URI(schema.url_in_s3).path.gsub(/^\//, ''))
    end
  end
end
