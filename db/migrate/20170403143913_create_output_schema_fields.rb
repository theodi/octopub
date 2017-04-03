class CreateOutputSchemaFields < ActiveRecord::Migration[5.0]
  def change
    create_table :output_schema_fields do |t|
      t.references  :output_schema, index: true
      t.references  :schema_field, index: true
      t.integer     :aggregation_type, default: 0, null: false, index: true
      t.timestamps
    end
  end
end
