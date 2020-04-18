class AddSchemaToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :schema, :json
  end
end
