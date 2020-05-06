class AddOwnerAvatarToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :owner_avatar, :string
  end
end
