class AddPrivateToDatasets < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :private, :boolean, :default => false
  end
end
