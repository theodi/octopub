class AddStorageKeysToDatasetFile < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_files, :storage_key, :string
  end
end
