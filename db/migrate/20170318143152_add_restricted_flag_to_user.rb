class AddRestrictedFlagToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :restricted, :boolean, default: false
  end
end
