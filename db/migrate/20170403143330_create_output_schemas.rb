class CreateOutputSchemas < ActiveRecord::Migration[5.0]
  def change
    create_table :output_schemas do |t|

      t.timestamps
    end
  end
end
