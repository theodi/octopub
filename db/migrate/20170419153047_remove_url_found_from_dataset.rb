class RemoveUrlFoundFromDataset < ActiveRecord::Migration[5.0]
  def change
    remove_column :datasets, :url_found, :boolean
  end
end
