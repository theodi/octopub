class DropRestrictedFlagFromDataset < ActiveRecord::Migration[5.0]
  def change
    remove_column :datasets, :deprecated_restricted, :boolean
  end
end
