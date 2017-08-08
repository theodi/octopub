class AddDatePatternToSchemaConstraints < ActiveRecord::Migration[5.0]
  def change
    add_column :schema_constraints, :date_pattern, :string, :default => nil
  end
end
