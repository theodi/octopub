class AddUserDetails < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :token, :string
  end
end
