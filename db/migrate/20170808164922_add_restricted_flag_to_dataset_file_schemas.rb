class AddRestrictedFlagToDatasetFileSchemas < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_file_schemas, :restricted, :boolean, default: true
  end
end
