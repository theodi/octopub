class AddStorageKeyToModels < ActiveRecord::Migration[5.0]
  def change
    add_column :models, :storage_key, :string
  end
end
