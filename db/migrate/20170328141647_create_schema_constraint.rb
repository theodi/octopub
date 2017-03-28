class CreateSchemaConstraint < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_constraints do |t|
      t.references  :schema_field
      t.boolean     :required, default: false
      t.boolean     :unique, default: false
      t.integer     :min_length
      t.integer     :max_length
      t.integer     :minimum
      t.integer     :maximum
      t.text        :pattern
      t.text        :type
    end
  end
end
