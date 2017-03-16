class AddOwnerDetailsToSchema < ActiveRecord::Migration[5.0]
  def change
    add_column :dataset_file_schemas, :owner_username, :text
    add_column :dataset_file_schemas, :owner_avatar_url, :text
  end
end
