class CreateDatasetSchemas < ActiveRecord::Migration[5.0]
  def change
    create_table :dataset_schemas do |t|
      t.text :name
      t.text :description
      t.text :url_in_s3
      t.text :url_in_repo
      t.json :schema
      t.belongs_to :user
    end
  end
end
