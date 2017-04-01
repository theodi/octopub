class AddSchemaTypeToSchema < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_file_schemas, :csv_on_the_web_schema, :boolean, default: false
  end
end
