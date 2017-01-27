class RenameDatasetSchemaToDatasetFileSchema < ActiveRecord::Migration[5.0]
  def change
    rename_table :dataset_schemas, :dataset_file_schemas
    remove_column :datasets, :dataset_schema_id
  end
end
