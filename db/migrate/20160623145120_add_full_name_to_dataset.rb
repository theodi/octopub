class AddFullNameToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :full_name, :string
    Dataset.all.each { |d| d.update_column(:full_name, d.full_name) }
  end
end
