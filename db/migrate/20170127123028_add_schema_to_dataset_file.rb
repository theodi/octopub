class AddSchemaToDatasetFile < ActiveRecord::Migration[5.0]
  def change
    add_reference :dataset_files, :dataset_file_schema, index: true
  end
end
