class AddPrivateToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :private, :boolean, :default => false
  end
end
