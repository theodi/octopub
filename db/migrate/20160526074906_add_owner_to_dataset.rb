class AddOwnerToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :owner, :string
  end
end
