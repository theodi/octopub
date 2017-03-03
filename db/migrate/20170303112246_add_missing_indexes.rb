class AddMissingIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :dataset_files, :dataset_id
    add_index :datasets, :user_id
  end
end
