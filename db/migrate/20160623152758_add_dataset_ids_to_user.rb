class AddDatasetIdsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :org_dataset_ids, :text, array: true, default: []
  end
end
