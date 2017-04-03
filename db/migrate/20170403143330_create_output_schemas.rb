class CreateOutputSchemas < ActiveRecord::Migration[5.0]
  def change
    create_table :output_schemas do |t|
      t.references  :dataset_file_schema, index: true
      t.references  :user, index: true
      t.text        :owner
      t.text        :title
      t.text        :description
      t.timestamps
    end
  end
end
