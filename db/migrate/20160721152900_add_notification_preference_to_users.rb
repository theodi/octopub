class AddNotificationPreferenceToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notification_preference, :integer, default: 0
  end
end
