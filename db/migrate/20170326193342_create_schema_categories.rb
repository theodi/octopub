class CreateSchemaCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_categories do |t|
      t.text        :name
      t.text        :description
      t.timestamps
    end

    create_table :schema_categories_dataset_file_schemas, id: false do |t|
      t.belongs_to :dataset_file_schema, index: { name: "schema_category_index"}
      t.belongs_to :schema_category, index: { name: "dataset_file_schema_index"}
    end
  end
end
