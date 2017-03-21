class AddPublishingMethodToDataset < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :publishing_method, :integer, default: 0, null: false
  end
end
