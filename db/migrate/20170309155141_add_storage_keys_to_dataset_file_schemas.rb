class AddStorageKeysToDatasetFileSchemas < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_file_schemas, :storage_key, :string
  end
end
