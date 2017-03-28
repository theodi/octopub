class CreateSchemaField < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_fields do |t|
      t.references  :dataset_file_schema
      t.text        :name, null: false
      t.text        :type
      t.text        :format
      t.timestamps
    end
  end
end
