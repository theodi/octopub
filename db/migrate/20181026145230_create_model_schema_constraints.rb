class CreateModelSchemaConstraints < ActiveRecord::Migration[5.0]
  def change
    create_table :model_schema_constraints do |t|
      t.text :description
      t.integer :schema_field_id
      t.boolean :required
      t.boolean :unique
      t.integer :min_length
      t.integer :max_length
      t.text :minimum
      t.text :maximum
      t.text :pattern
      t.text :type
      t.string :date_pattern
      t.belongs_to :model_schema_field, foreign_key: true

      t.timestamps
    end
  end
end
