class AddUrlFoundFieldToDataset < ActiveRecord::Migration[5.0]
  def change
    add_column :datasets, :url_found, :boolean
  end
end
