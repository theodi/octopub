class CreateModelSchemaFields < ActiveRecord::Migration[5.0]
  def change
    create_table :model_schema_fields do |t|
      t.integer :model_id
      t.text :name
      t.text :description
      t.text :title
      t.integer :type
      t.text :format
      t.belongs_to :model, foreign_key: true

      t.timestamps
    end
  end
end
