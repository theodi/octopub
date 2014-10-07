class AddExtraFieldsToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :description, :string
    add_column :datasets, :publisher_name, :string
    add_column :datasets, :publisher_url, :string
    add_column :datasets, :license, :string
    add_column :datasets, :frequency, :string
  end
end
