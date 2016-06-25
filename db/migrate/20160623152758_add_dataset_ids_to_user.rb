class AddDatasetIdsToUser < ActiveRecord::Migration
  def change
    add_column :users, :org_dataset_ids, :text, array: true, default: []
  end
end
