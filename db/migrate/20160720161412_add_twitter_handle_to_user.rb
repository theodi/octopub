class AddTwitterHandleToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :twitter_handle, :string
  end
end
