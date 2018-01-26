class AddPublishedStatusToDatasets < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :published_status, :boolean, :default => false
  end
end
