class RenameDatasetSchemaToDatasetFileSchema < ActiveRecord::Migration[5.0]
  def change
    rename_table :dataset_schemas, :dataset_file_schemas
    rename_column :datasets, :dataset_schema_id, :dataset_file_schema_id
  end
end
