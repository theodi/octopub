class AddOwnerAvatarToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :owner_avatar, :string
  end
end
