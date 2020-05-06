class AddOwnerToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :owner, :string
  end
end
