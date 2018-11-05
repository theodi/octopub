class RemoveSchemaFieldIdFromModelSchemaConstraints < ActiveRecord::Migration[5.0]
  def change
    remove_column :model_schema_constraints, :schema_field_id, :integer
  end
end
